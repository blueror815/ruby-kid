module Trading
  class BuyRequest < ActiveRecord::Base
    attr_accessible :message, :name, :email, :phone, :parent_message

    object_constants :status, :pending, :declined, :waiting_for_sell, :sold, :canceled
    STATUSES.each do |s|
      define_method "#{s.downcase}?" do
        status.to_s.upcase == "#{s}"
      end
    end

    belongs_to :buyer, class_name:'User', foreign_key:'buyer_id'
    belongs_to :seller, class_name:'User', foreign_key:'seller_id'
    has_and_belongs_to_many :items, :join_table => 'buy_requests_items'

    scope :pending, conditions: ["status = ?", Status::PENDING]
    scope :waiting_for_sell, conditions: ["status = ?", Status::WAITING_FOR_SELL]
    scope :not_sold, conditions: ["status != ?", Status::SOLD]

    before_save :set_defaults!
    after_create :create_notification!, if: Proc.new {|br| br.buyer.is_a?(Child)}
    after_create :tell_seller_parent!, if: Proc.new{|br| br.buyer.is_a?(Parent)}
    after_update :update_others!, if: Proc.new {|br| br.buyer.is_a?(Child)}

    validates_presence_of :buyer_id, :seller_id
    validate :check_attributes

    def as_json(options = {})
      h = super(options)
      h[:items] = items.collect(&:as_json)
      h[:child] = buyer.as_json
      h[:buyer] = buyer.as_json
      h[:seller] = seller.as_json
      h
    end

    # Minimized JSON - least DB queries
    def active_trade_info
      h = self.attributes.select{|k,v| [:id, :buyer_id, :seller_id, :message, :name, :email, :phone, :parent_message, :created_at].include?(k.to_sym) }
      h[:buyer] = buyer.as_json
      h
    end

    #########################
    # Tasks

    NOT_SOLD_EXPIRATION_LENGTH = 1.week

    def self.expire_not_sold
      start_time = Time.now - NOT_SOLD_EXPIRATION_LENGTH
      total_not_sold_count = not_sold.where(["created_at < ?", start_time] ).count

      puts "# #{total_not_sold_count} found since started on #{start_time.to_s(:db)}"

      if total_not_sold_count > 0
        not_sold.where(["created_at < ?", start_time] ).to_a.each do|buy_request|
          puts "- BuyRequest(#{buy_request.id}), buyer #{buy_request.buyer_id}"
          buy_request.status = Status::CANCELED
          buy_request.save
        end
      end
    end

    protected

    def set_defaults!

      unless STATUSES.include?(self.status.to_s.upcase.to_sym)
        self.status = Status::PENDING
      end
    end

    def tell_seller_parent!
      return if seller.parent.nil? || !seller.requires_parental_guidance?

      #send email to the other parent. This is only called after the parent sends out the request.
      self.status = Status::WAITING_FOR_SELL
      child_id = buyer.children.first.id
      ::NotificationMail.create_from_mail(child_id, seller.parent_id, UserMailer.new_buy_request_to_seller_parent(self))
    end

    def check_attributes
      if self.items.blank?
        self.errors.add(:items, "Cannot find valid items for buying.")
      end
      if waiting_for_sell?
        self.errors.add(:parent_message, "Message is required") if parent_message.blank?
        self.errors.add(:name, "Name is required") if name.blank?
        self.errors.add(:email, "Email for contact is required") if email.blank?
        self.errors.add(:email, "This email is invalid") if email && !email.strip.valid_email?
      end
    end

    ##
    # Initial creation of this purchase: notification and email
    def create_notification!
      ::Users::Notifications::NewBuyRequest.create(
          recipient_user_id: buyer.parent_id, sender_user_id: buyer_id, related_model_type:'Trading::BuyRequest', related_model_id: self.id,
          uri: Rails.application.routes.url_helpers.buy_request_path(self)
      )
      ::NotificationMail.create_from_mail(buyer_id, buyer.parent_id, UserMailer.new_buy_request(self.items.first, buyer) )
    end

    # At this point, expected record valid.
    def update_others!
      if status_changed?

        if waiting_for_sell? || declined?
          ::Users::Notification.where(related_model_type:'Trading::BuyRequest', related_model_id: self.id).update_all(status: ::Users::Notification::Status::DELETED)
        end

        if waiting_for_sell?
          self.items.each{|item| item.status = ::Item::Status::BUYING; item.save; }

        elsif declined? || canceled?

          self.items.each{|item| item.activate! }

        elsif sold?

          self.items.each{|item| item.deactivate! }
          ::NotificationMail.create_from_mail(buyer.parent_id, seller.parent_id, UserMailer.new_buy_request_to_seller_parent(self) )

        end
      end
    end
  end
end
