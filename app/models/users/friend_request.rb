module Users
  class FriendRequest < ActiveRecord::Base
    attr_accessible :recipient_user_id, :requester_user_id, :recipient_message, :requester_message, :status,
                    :requester_parent_id, :recipient_parent_id, :created_at, :updated_at


    attr_accessor :requires_parent_approval

    REQUIRES_PARENT_APPROVAL = false
    
    STATUS = { sent_request_parent: 0, accept_request_parent: 1, sent_recip_child: 2, accept_recip_child: 3,
               accepted_full: 4, denied: 5 }

    validates_uniqueness_of :requester_user_id, :scope => :recipient_user_id

    belongs_to :requester, class_name:'User', foreign_key: 'requester_user_id'
    belongs_to :requester_parent, class_name:'User', foreign_key: 'requester_parent_id'
    belongs_to :recipient, class_name:'User', foreign_key: 'recipient_user_id'
    belongs_to :recipient_parent, class_name:'User', foreign_key: 'recipient_parent_id'

    after_create :create_notification!
    before_create :establish_parents!

    def status
      STATUS.key(read_attribute(:status))
    end

    def status=(s)
      write_attribute(:status, STATUS[s])
    end

    # If instance variable requires_parent_approval not yet, uses the default constant REQUIRES_PARENT_APPROVAL.
    def requires_parent_approval?
      requires_parent_approval.nil? ? REQUIRES_PARENT_APPROVAL : requires_parent_approval
    end

    ##
    # According to status, can be either requester or in reverse recipient who wants to follow
    # @return <User>
    def current_request_child
      (status == :accept_recip_child || status == :accepted_full ) ? recipient : requester
    end

    ##
    # According to status, can be either recipient or in reverse requester being followed
    # @return <User>
    def current_recipient_child
      (status == :accept_recip_child || status == :accepted_full ) ? requester : recipient
    end

    def current_message
      (status == :accept_recip_child || status == :accepted_full ) ? recipient_message : requester_message
    end

    def create_notification!
        #send request to parent
      if requires_parent_approval?
        user_attr = {recipient_user_id: requester_parent_id, sender_user_id: requester_user_id}
        if ::Users::Notifications::KidAddFriendToParent.where(user_attr).empty?
          ::Users::Notifications::KidAddFriendToParent.create( user_attr.merge({ uri: "/friend_request/#{self.id}", related_model_type: "Users::FriendRequest", related_model_id: self.id }) )

          create_notification_mail!
        end

      else # Immediately skip to notify child B
        self.status = :sent_recip_child
        self.save

        ::Users::Notifications::KidAddFriendToKid.create_if_needed(self)
      end
    end

    # email to parent, depending on status whether :sent_request_parent or :accept_recip_child
    def create_notification_mail!
      sender = status.eql?(:accept_recip_child) ? recipient : requester
      the_other_child = status.eql?(:accept_recip_child) ? requester : recipient
      ::NotificationMail.create_from_mail(sender.id, sender.parent_id, ::UserMailer.friend_request(self, sender, the_other_child),
                                          'friend_request', self.id)
    end

    def as_json(requesting_user_id)
      #this will give different results based on the user_id that is requesting
      if requesting_user_id.eql? requester_parent_id
        if requester_message.nil?
          message = ""
        else
          message = requester_message
        end
        result = {
            bottom_user: User.find(recipient_user_id).as_json,
            message_user: User.find(requester_user_id).as_json,
            message: message
        }
      elsif requesting_user_id.eql? recipient_user_id
        requester_json = requester.as_json
        result = {
            bottom_user: requester_json,
            message_user: requires_parent_approval? ? {} : requester_json,
            message: requires_parent_approval? ? '' : requester_message
        }
      elsif requesting_user_id.eql? recipient_parent_id
        if recipient_message.nil?
          message = ""
        else
          message = recipient_message
        end
        result = {
            bottom_user: User.find(requester_user_id).as_json,
            message_user: User.find(recipient_user_id).as_json,
            message: message
        }
      else
        result = {}
      end
      result
    end

    #gateway method so

    #{ sent_request_parent: 0, accept_request_parent: 1, sent_recip_child: 2, accept_recip_child: 3,
    #            accepted_full: 4, denied: 5 }
    def accept(action_user_id, message)
      result = false
      if action_user_id.eql? self.requester_parent_id and self.status.eql? :sent_request_parent
        #this should send the message to the recipient_user_id
        ::Users::Notifications::KidAddFriendToParent.where(recipient_user_id: requester_parent_id, sender_user_id: requester_user_id).delete_all

        ::Users::Notifications::KidAddFriendToKid.create_if_needed(self)

        #set status to sent_recip_child
        self.status = :sent_recip_child
        self.save
        result = true

      elsif action_user_id.eql? self.recipient_user_id and self.status.eql? :sent_recip_child

        ::Users::Notifications::KidAddFriendToKid.where(recipient_user_id: recipient_user_id, sender_user_id: requester_user_id).delete_all

        if requires_parent_approval?

          self.status = :accept_recip_child
          self.recipient_message = message
          self.save
          if ::Users::Notifications::KidAddFriendToParent.create_if_needed(self)
            # email to recipient_parent
            self.create_notification_mail!
          end
          result = true

        else # Child's agreement finishes it

          result = set_accepted_full!
        end

      elsif action_user_id.eql? self.recipient_parent_id and self.status.eql? :accept_recip_child

        result = set_accepted_full!
      end
      result
    end

    def set_accepted_full!
      self.status = :accepted_full
      ::Stores::Following.create(user_id: requester_user_id, follower_user_id: recipient_user_id, friend_request: true)
      ::Stores::Following.create(user_id: recipient_user_id, follower_user_id: requester_user_id, friend_request: true)

      ::Users::Notifications::KidAddFriendToParent.where(recipient_user_id: recipient_parent_id, sender_user_id: recipient_user_id).delete_all
      #actually create the friend request stuffs.
      self.save
    end

    def waiting_for_response_of?(action_user_id)
      action_user_id = action_user_id.id if action_user_id.is_a?(User)
      case status
        when :sent_request_parent
          action_user_id.eql? self.requester_parent_id
        when :sent_recip_child
          action_user_id.eql? self.recipient_user_id
        when :accept_recip_child
          action_user_id.eql? self.recipient_parent_id
        else
          false
      end
    end

    private

    def establish_parents!
      self.requester_parent_id ||= requester.parent_id
      self.recipient_parent_id ||= recipient.parent_id
    end

  end
end
