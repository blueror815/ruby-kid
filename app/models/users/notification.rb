module Users
  class Notification < ActiveRecord::Base

    self.table_name = 'notifications'

    attr_accessible :sender_user_id, :recipient_user_id, :title, :uri, :local_references_code, :status, :related_model_type,
                    :related_model_id, :tip, :expires_at, :action_icon
    attr_accessor :related_model

    object_constants :status, :wait, :viewed, :deleted

    belongs_to :sender, class_name: 'User', foreign_key: 'sender_user_id'
    belongs_to :recipient, class_name: 'User', foreign_key: 'recipient_user_id'

    scope :sent_to, lambda {|user| where(recipient_user_id: user) }
    scope :in_wait, where(:status => Status::WAIT)
    scope :not_deleted, where("status != 'DELETED'")
    scope :already_viewed, where(:status => Status::VIEWED)
    scope :expired, where("expires_at IS NOT NULL AND expires_at < NOW()")

    # This list represents those web-version action pages already implemented, so can pass the notifications filter to
    # show only these actions for the parent to respond.  Therefore, this list will change once more are implemented.
    scope :parent_required, where(type: ['Users::Notifications::NeedsAccountConfirm',
                                         'Users::Notifications::IsWaitingForApproval', 'Users::Notifications::TradeParentApproval',
                                         'Users::Notifications::TradeParentApprovalBuyer'] )

    before_save :set_defaults
    after_create :send_push_notification
    before_update :set_expiration, if: Proc.new {|note| note.expire_after_view?}
    #after_update :update_others!, if: Proc.new {|br| br.buyer.is_a?(Child)}

    STATUSES.each do |s|
      define_method "#{s.downcase}?" do
        status.to_s.upcase == "#{s}"
      end
    end

    self.per_page = 50

    def expire_after_view?
      false
    end

    def self.define_android_app(auth_key)
      app = Rpush::Gcm::App.new
      app.name = "KidsTrade_android"
      app.auth_key = auth_key
      app.connections = 1
      app.save!
    end

    def send_push_notification

      notification_text = self.text_for_push_notification

      puts "----self for notification.rb----W/#{self}"
      puts "----notification text for notification.rb--------W/#{notification_text}"

      return if notification_text == nil

      devices = ::Users::UserNotificationToken.where(user_id: self.recipient_user_id)
      #changing to only send it to the last device token registered
      devices.each do |device|
        unless device.nil?
          if device.platform_type.eql? ::Users::UserNotificationToken::IOS
            send_ios_push_notification(notification_text, device.token)
          else
            send_android_push_notification(notification_text, device.token)
          end
        end
      end
    end

    def send_android_push_notification(notification_text, token)
      note = Rpush::Gcm::Notification.new
      note.app = Rpush::Gcm::App.find_by_name("KidsTrade_android")
      note.registration_ids = [token]
      note.data = {message: notification_text}
      note.save!
    end

    def send_ios_push_notification(notification_text, token)
      #using houston to send IOS notification
      # notification = Houston::Notification.new(device: token)
      # notification.alert = notification_text
      # notification.sound = "apns.caf"
      # note_count = reject_notes(::Users::Notification.sent_to(self.recipient_user_id).not_deleted.includes(:sender)).count
      # notification.badge = note_count
      # notification.custom_data = {trade_id: get_trade_id, type: get_type.to_s, notification_count: note_count}
      # #the server hangs if the token isn't correct, so uncomment this when the token is valid.
      # APN.push(notification)

      puts("----token for notification.rb-------", token)

      if Rails.env.production?
        pusher = Grocer.pusher(
            # certificate: File.read(Rails.root.join('config/certificates/CubbyShop-Production-APNS-Certificates.pem')),
            certificate: File.join(Rails.root, 'config/certificates', 'CubbyShop-Production-APNS-Certificates.pem'),
            passphrase: "",
            gateway: "gateway.push.apple.com",
            port: 2195,
            retires: 3
        )   
      else
        pusher = Grocer.pusher(
            # certificate: File.read(Rails.root.join('config/certificates/CubbyShop-Push-Dev-Certificates.pem')),
            certificate: File.join(Rails.root, 'config/certificates', 'CubbyShop-Push-Dev-Certificates.pem'),
            passphrase: "",
            gateway: "gateway.sandbox.push.apple.com",
            port: 2195,
            retires: 3
        )
      end

      puts "-------recipient user id for notification.rb----W/#{self.recipient_user_id}"

      notification = Grocer::Notification.new(device_token: token)
      notification.alert = notification_text
      notification.sound = "apns.caf"
      note_count = ::Users::Notification.reject_notes(::Users::Notification.sent_to(self.recipient_user_id).not_deleted.includes(:sender)).count
      notification.badge = note_count
      puts "-------note count for notification.rb----W/#{note_count}"
      notification.custom = {trade_id: get_trade_id, type: get_type.to_s, notification_count: note_count}

      pusher.push(notification)

    end

    def self.reject_notes(notifications)
      puts "-------notification for notification.rb----W/#{notifications}"
      notifications.reject {|note| (note.title.eql? "" or note.tip.eql? 'Trade Details')}
    end

    def get_trade_id
      trade = self.related_model
      return nil if trade.nil?
      trade.id
    end

    def get_type
      nil
    end

    #this method is purely for testing since we can't test push notifications from the rails app.
    def test_type_and_trade_id
      to_return = [get_type, get_trade_id]
      to_return
    end

    def waiting?
      status == Status::WAIT
    end

    def set_status_deleted
      update_attribute(:status, ::Users::Notification::Status::DELETED)
    end

    def related_model(*includes)
      if related_model_type.present? && related_model_id.to_i > 0
        if @related_model.nil?
          query = related_model_type.constantize.where(id: related_model_id)
          query = query.includes(includes) if includes.present?
          @related_model = query.first
        end
        @related_model
      else
        nil
      end
    rescue
      nil
    end

    ##
    # Queries the related models in batch, and set them accordingly to each in list.
    def self.set_related_models(list)
      whole_group = list.group_by(&:related_model_type)
      if list.size / whole_group.size.to_f > 2.0 # Only worth if many entries have same related_model_type
        whole_group.each_pair do|related_model_type, sublist|
          if not related_model_type.nil?
            related_class = related_model_type.constantize
            related_model_map = related_class.where(id: sublist.collect(&:related_model_id) ).group_by(&:id)
            sublist.each do|obj|
              if not related_model_map[obj.related_model_id].nil?
                obj.related_model = related_model_map[obj.related_model_id].first
              end
            end
          end
        end
      end
    end

    # Attributes:
    #   +local_references_code+: a JSON hash
    #      "@item=Item.last;@user=User.find(1)"
    # @return <Hash, string-keys>

    def local_references
      return {} if local_references_code.blank?
      JSON.parse(local_references_code)
    rescue JSON::ParserError
      {}
    end

    ##
    # Simplified to let record-cache do the job of caching queries.
    def get_cache(identifier, language)
      ::NotificationText.get_cache(identifier, language)
    end

    def sub_context_specific_words(text)
      text_copy = text.clone
      context_specific_notification_text.each do |keyword, value|
        text_copy.gsub!(keyword, value)
      end
      text_copy
    end

    def get_property(property_name)
      row_result = get_cache(copy_identifier, 'en')
      text = row_result.try(property_name)
      if text.present?
        if text.index('%') != nil
          sub_context_specific_words( text )
        else
          text.split("\n").shuffle.first
        end
      else
        nil
      end
    end

    def title
      get_property(:title)
    end

    def tip
      get_property(:subtitle)
    end

    def title_for_item
      get_property(:title_for_item)
    end

    def subtitle_for_item
      get_property(:subtitle_for_item)
    end

    def title_for_trade
      get_property(:title_for_trade)
    end

    def subtitle_for_trade
      get_property(:subtitle_for_trade)
    end

    def text_for_push_notification
      puts "-------self text push notification-------/"
      get_property(:push_notification)
    end

    def title_for_parent
      get_property(:title_for_parent)
    end

    def tip_for_parent
      get_property(:tip_for_parent)
    end

    def title_for_trade_b
      get_property(:title_for_trade_b)
    end

    def tip_for_trade_b
      get_property(:tip_for_trade_b)
    end

    def title_for_item_b
      get_property(:title_for_item_b)
    end

    def tip_for_item_b
      get_property(:tip_for_item_b)
    end

    def copy_identifier
      nil
    end

    def context_specific_notification_text
      replace_dictionary = {
          '%{sender_possessive_pronoun}' => sender.pronoun_form.titleize,
          '%{sender_possessive_form}' => sender.possessive_form.titleize,
          '%{sender_object_form}' => sender.object_form,
          '%{sender_owner_form}' => sender.female? ? 'her' : 'his',
          '%{sender_pronoun_form}' => sender.female? ? 'She' : 'He',
          '%{sender_name}' => sender.user_name
      }
      replace_dictionary
    end

    ADDITIONAL_ACTIONS = 'additional_actions'

    ##
    # return <Array of <Hash: action_key => action_value> >
    def add_additional_action! (action_key, action_value)
      actions = additional_actions
      actions << {action_key => action_value}
      set_local_reference!( ADDITIONAL_ACTIONS, actions)
      actions
    end

    def set_local_reference!(key, value)
      h = local_references
      h[key] = value
      self.local_references_code = JSON.dump(h)
      self.save
    end

    def additional_actions
      local_references[ADDITIONAL_ACTIONS] || []
    end

    def short_type
      self.type.gsub(/((::)?Users::Notifications::)/i, '').underscore
    end

    ##
    # Certain types of notification are more important for user action, such as trade actions or soon to expire time.
    def priority
      self_score = ( self.type.to_s =~ /Trade/ ) ? 40 : 0
      self_score += ( self.type =~ /IsWaitingForApproval/ ) ? 60 : 0
      self_score += 10 if self.expires_at && self.expires_at - Time.now < 6.hours
      self_score += 20 if self.waiting?
      self_score += 100 if self.starred
      self_score
    end

    def starred
      false
    end

    # return <Boolean>
    def additional_action_taken
      additional_actions.present?
    end

    # @return <Integer> whether -1, 0, or 1
    def compares_with(another)
      comp = another.priority <=> self.priority
      comp = (another.created_at <=> self.created_at) if comp == 0
      comp
    end

    def should_flag_viewed?
      self.starred == false && self.is_a?(::Users::Notifications::TradeBasic) == false
    end

    def should_be_deleted_after_view?
      false
    end


    ACTION_ICONS = %w|trade question like other|

    ##
    # @return <String> might be nil or empty or one of the ACTION_ICONS in lowercase.
    def action_icon
      'other'
    end

    ##
    # Extra options:
    #   :relationship_to_user <User>: passed onto User attributes to better rename the users;
    #     for example, pass in the child and sender being the father would show name 'Dad'

    def as_json(options = {})
      relationship_to_user = options.delete(:relationship_to_user)
      h = super(except: [:local_references_code, :updated_at, :type], methods: [:priority, :starred, :additional_action_taken, :action_icon] )
      h.merge!(sender: self.sender.as_json({relationship_to_user: relationship_to_user}))
      h[:type] = short_type
      h
    end

    # @deprecated Use subclasses of Notifications::Basic
    def self.set_types_based_on_titles
      where("type IS NULL OR type = ''").each do|n|
        t = 'Basic'
        if n.title =~ /likes your item/i
          t = 'LikeItem'
          n.updated_at = 1.hour.ago
        elsif n.title =~ /has a (question|comment)/i
          t = 'HasComment'
        elsif n.title =~ /following your shop/i
          t = 'IsFollowing'
        elsif n.title =~ /wants to trade/i
          t = 'TradeNew'
        end
        n.type = 'Users::Notifications::' + t
        n.save
      end
    end

    protected

    def set_defaults
      if self.respond_to?(:type)
        self.type ||= 'Users::Notifications::Basic'
      end
      self.status = Status::WAIT if self.status.blank? || !STATUSES.include?(self.status.upcase) && !STATUSES.include?(self.status.upcase.to_sym)
    end

    def set_expiration
      #set the expiration for the current message.
      self.expires_at = DateTime.now + 1.day
    end

  end
end
