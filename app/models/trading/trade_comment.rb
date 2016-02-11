class Trading::TradeComment < ActiveRecord::Base
  attr_accessible :comment, :item_id, :price, :user_id, :status, :is_meeting_place

  delegate :editable_by_user?, :to => :trade

  object_constants :status, :wait, :replied, :bought, :accepted, :declined, :trade_ended, :trade_removed, :disagreed, :agreed,
                   :report_suspended, :report_deleted

  belongs_to :trade, class_name: 'Trading::Trade'
  belongs_to :item
  belongs_to :user

  scope :waiting, conditions: ["status = ?", Status::WAIT]

  before_save :set_defaults!
  after_save :async_filter

  def waiting?
    status == Status::WAIT
  end

  STATUSES.each do |s|
    define_method "#{s.downcase}?" do
      status.to_s.upcase == "#{s}"
    end
  end

  # An action that changes status of the bundle, such as accept or decline
  def decisive_action?
    accepted? || declined?
  end

  def created_by_buyer?
    if item
      item.user_id != user_id
    else
      trade.buyer_id == user_id
    end
  end

  def created_by_seller?
    if item
      item.user_id == user_id
    else
      trade.seller_id == user_id
    end
  end

  def the_other_user_id(current_user_id = nil)
    current_user_id ||= user_id
    (current_user_id == trade.buyer_id) ? trade.seller_id : trade.buyer_id
  end

  def the_other_user
    User.find_by_id(the_other_user_id)
  end

  def as_json(options = {} )
    recipient = self.the_other_user
    { trade_id: trade_id, body: comment, created_at: created_at.utc.to_s(:utc), user: user.as_more_json({}, the_other_user_id),
      recipient_user_id: recipient.id, recipient: recipient.as_json, is_meeting_place: is_meeting_place }
  end

  #######################
  # Notification

  # Different types of offer messages
  # * Jake wants to trade
  # * Jake has accepted offer
  # * Jake has bought

  def notification_title
    case status.upcase
      when Status::BOUGHT
        'Has Bought'
      when Status::ACCEPTED
        'Has Accepted Trade'
      when Status::DECLINED
        'Has Declined Trade'
      when Status::REPORT_SUSPENDED
        'Reported and Suspended'
      else
        'Wants to Trade'
    end
  end


  private


  def set_defaults!
    self.status = Status::WAIT if status.blank?
  end

  def async_filter

    ::FilterRecordWorker.perform_async(user_id, 'Trading::TradeComment', self.id, ['comment'])
  rescue Exception => exception
    ::Jobs::RecordFilter.new(user_id, 'Trading::TradeComment', self.id, ['comment']).enqueue!
  end

end
