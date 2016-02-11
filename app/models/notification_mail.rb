class NotificationMail < ActiveRecord::Base

  attr_accessible :sender_user_id, :recipient_user_id, :mail, :status, :trial_count, :related_type, :related_type_id

  belongs_to :sender, foreign_key: 'sender_user_id', class_name: 'User'
  belongs_to :recipient, foreign_key: 'recipient_user_id', class_name: 'User'

  scope :drafts, where( status: 'DRAFT')
  scope :sent, where( status: 'SENT')

  def self.send_account_confirm_emails
    parents = User.where(account_confirmed: false)
    parents.each do |user|
      if user.is_a?(Parent)
        has_approved_items = false
        user.children.each do |child|
          break if has_approved_items
          items_count = Item.pending_account_confirmation.where(user_id: child.id).count
          if items_count > 0
            has_approved_items = true
          end
        end
        if has_approved_items
          #if NotificationMail.where()
          #if ::NotificationMail.where(recipient_user_id: user.id, type: ).empty?
          if ::NotificationMail.where(recipient_user_id: user.id, related_type: "confirm").empty?
            ::NotificationMail.create_from_mail(Admin.cubbyshop_admin.id, user.id, UserMailer.account_confirmation_available(user), "confirm")
          end
        end
      end
    end
  end

  def self.create_from_mail(sender_user_id, recipient_user_id, mail, related_type = nil, related_type_id = nil)
    make_from_mail(sender_user_id, recipient_user_id, mail, related_type, related_type_id).save
  end

  ##
  # mail <String or Mail::Message>
  def self.make_from_mail(sender_user_id, recipient_user_id, mail, related_type = nil, related_type_id = nil)
    new(sender_user_id: sender_user_id, recipient_user_id: recipient_user_id, mail: mail.to_s,
        related_type: related_type, related_type_id: related_type_id, status: 'DRAFT')
  end

  ##
  # Allowing 3 trials per 8 hours.  And no past than a day.
  def should_auto_deliver?
    return false if Time.now - created_at > 1.day
    trial_count < ((Time.now - created_at) / 8.hours ).ceil * 3
  end

  ##
  # Checks if mail should_auto_deliver? before calling deliver!
  def auto_deliver!
    if should_auto_deliver?
      deliver!
    end
  end

  def deliver!
    self.update_attribute(:trial_count, trial_count.to_i + 1)
    m = Mail.new(self.mail).deliver
    self.update_attributes(status: 'SENT')
  end

  ##
  # After certain amount of time
  def mark_stale_if_needed!
    self.update_attributes(status: 'FAILED') if status == 'DRAFT' && Time.now - created_at > 1.day
  end

  NUMBER_OF_MAILS_PER_SECOND = 5

  ##
  #
  def self.deliver_drafts
    total_count = [drafts.count, 100].min
    i = 0
    while i < total_count
      drafts.limit(NUMBER_OF_MAILS_PER_SECOND).order('id asc').to_a.each do|m|
        mail = Mail.new(m.mail)
        if not m.should_auto_deliver?
          m.update_attributes(status: 'ARCHIVED' )
          logger.info "| #{m.id} archived, originally to #{mail.to}"
          next
        end
        begin
          logger.info "| #{m.id} |-- to #{mail.to} @ #{Time.now.to_s(:db)}"
          m.deliver!
        rescue Exception => e
          logger.error "  ** Delivery error: #{e.message}"
        end
      end
      i += NUMBER_OF_MAILS_PER_SECOND
      sleep(1)
    end
  end
end
