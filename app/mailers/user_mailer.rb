class UserMailer < ActionMailer::Base
  default from: "\"KidsTrade\" <notices@kidstrade.com>"

  ############################
  # Selling

  ##
  def check_new_item(item, parent = nil)
    parent ||= item.user.parent
    @item = item
    @recipient = parent
    @sender = @item.user
    @relationship = @recipient.informal_relationship_to(@sender)
    context_h = { sender_name: @sender.display_name.titleize, sender_pronoun: @sender.try(:pronoun_form) || 'the child'}

    @main_paragraphs = t('parenting.check_new_item.email_main_paragraphs', context_h)
    @sub_paragraphs = t('parenting.check_new_item.email_sub_paragraphs', context_h)
    @subject = t('parenting.check_new_item.email_subject', )

    mail(to: parent.email, subject: @subject)
  end

  ##
  # status <String or Symbol> optional. [:first, :reapproval, :followup].  If not specified, fetch_item_for_approval_status 
  # would be called to determine the content/wording of the message.
  def item_for_approval(item, parent, status = nil)
    status ||= self.class.fetch_item_for_approval_status(item, parent)
    @item = item
    @recipient = parent
    @sender = @item.user
    @relationship = @recipient.informal_relationship_to(@sender)
    context_h = { sender_name: @sender.display_name.titleize, sender_pronoun: @sender.try(:pronoun_form) || 'the child'}
    
    if status.to_s.to_sym == :first
      @main_paragraphs = t('parenting.item_approval.email_main_paragraphs', context_h )
      @sub_paragraphs = t('parenting.item_approval.email_sub_paragraphs', context_h )
      @subject = t('parenting.item_approval.email_subject')

    elsif status.to_s.to_sym == :reapproval
      @main_paragraphs = ["Your child edited an item that was already approved."]
      @sub_paragraphs = [
          "Take a moment to review the changes and approve again.  Let's get this stuff back on the shelves asap!"
      ]
      @subject = "#{@sender.display_name.titleize} made some changes. Please approve!"


    else #################
      @main_paragraphs = t("parenting.item_approval.email_main_paragraphs")
      @sub_paragraphs = t("parenting.item_approval.email_sub_paragraphs")
      @subject = t("parenting.item_approval.email_subject", sender_name: @sender.display_name.titleize)
    end

    mail(to: parent.email, subject: @subject)
  end

  def business_card(user, attachment_url = nil)
    @user = user
    @subject = "KidsTrade Business Card"
    if attachment_url.present?
      begin
        file_name = "#{user.user_name}.pdf"
        remote_data = open(attachment_url).read

        attachments[file_name] = {mime_type: 'application/pdf', content: remote_data }
      rescue Exception => e
        logger.warn "=============================\n** business_card error: #{e.message}\n" << e.backtrace.join("\n\t")
      end
    end
    mail(to: user.parent.email, subject: @subject)
  end

  ##
  # Determine what's the status of the parent's item approval, whether it's :first, :reapproval, or :followup
  def self.fetch_item_for_approval_status(item, parent)
    total_mail_count = ::NotificationMail.where(recipient_user_id: parent.id, sender_user_id: item.user_id, related_type: 'item_for_approval').count
    if total_mail_count == 0 # 1st time
      puts " .. Creating 1st mail for parent #{parent.id}"
      :first
    elsif item.updated_at > item.created_at + 10.minutes
      puts " .. Creating re-approval mail for parent #{parent.id}"
      :reapprove
    else
      puts " .. Creating re-approval mail for parent #{parent.id}"
      :followup
    end
  end

  ############################
  # Parenting

  def trade_approval(trade, waiting_user)
    @sender = waiting_user
    @recipient = waiting_user.parents.first
    @trade = trade
    @relationship = @recipient.informal_relationship_to(@sender)
    puts "Relationship: #{@relationship.titleize}"
    @main_paragraphs = t("parenting.trade_approval.email_main_paragraphs")
    @sub_paragraphs = t("parenting.trade_approval.email_sub_paragraphs")
    @subject = t("parenting.trade_approval.email_subject", sender_name: @sender.display_name.titleize)

    mail(to: @recipient.email, subject: @subject)
  end

  # child <User> If not specified, would be set to report.offender
  def child_reported(report, child = nil)
    child ||= report.offender
    @sender = ::Admin.cubbyshop_admin
    @recipient = child.parent
    @report = report
    @greeting = t("parenting.your_child_was_reported.email_greeting", parent_first_name: child.parent.first_name.titleize)
    @main_paragraphs = t("parenting.your_child_was_reported.email_main_paragraphs")
    @sub_paragraphs = t("parenting.your_child_was_reported.email_sub_paragraphs", child_first_name: child.first_name.titleize)
    @sub_paragraphs.each_with_index do|p, idx|
      @sub_paragraphs[idx] = p.gsub("%{child_first_name}", child.first_name.titleize)
    end
    @subject = t("parenting.your_child_was_reported.email_subject", child_first_name: child.first_name.titleize)

    mail(to: @recipient.email, subject: @subject)
  end

  def incomplete_registration(user)
    @sender = ::Admin.cubbyshop_admin
    @recipient = user

    @main_paragraphs = t("parenting.incomplete_registration.email_main_paragraphs")
    @sub_paragraphs = t("parenting.incomplete_registration.email_sub_paragraphs")
    @subject = t("parenting.incomplete_registration.email_subject")

    mail(to: @recipient.email, subject: @subject)
  end

  ############################
  # Abandonment Emails

  def load_child_data(child, parent = nil)
    @child = child
    @parent = parent || @child.parent

    @sender = ::Admin.cubbyshop_admin
    @recipient = @child.parent
  end

  def child_login_reminder(child, parent = nil)
    load_child_data(child, parent)

    @main_paragraphs = t('parenting.child_login_reminder.email_main_paragraphs').collect{|line| line.evaluate_with_variables(child_attributes) }
    @sub_paragraphs = t('parenting.child_login_reminder.email_sub_paragraphs').collect{|line| line.evaluate_with_variables(child_attributes) }
    @subject = t('parenting.child_login_reminder.email_subject', child_attributes)

    mail(to: @recipient.email, subject: @subject)
  end

  def child_posting_reminder(child, parent = nil)
    load_child_data(child, parent)

    @main_paragraphs = t('parenting.child_posting_reminder.email_main_paragraphs').collect{|line| line.evaluate_with_variables(child_attributes) }
    @sub_paragraphs = t('parenting.child_posting_reminder.email_sub_paragraphs').collect{|line| line.evaluate_with_variables(child_attributes) }
    @subject = t('parenting.child_posting_reminder.email_subject', child_attributes)

    mail(to: @recipient.email, subject: @subject)
  end

  def item_approval_reminder(child, parent = nil)
    load_child_data(child, parent)

    @main_paragraphs = t('parenting.item_approval_reminder.email_main_paragraphs').collect{|line| line.evaluate_with_variables(child_attributes) }
    @sub_paragraphs = t('parenting.item_approval_reminder.email_sub_paragraphs').collect{|line| line.evaluate_with_variables(child_attributes) }
    @subject = t('parenting.item_approval_reminder.email_subject', child_attributes)

    mail(to: @recipient.email, subject: @subject)
  end

  def verify_account_reminder(parent)
    @parent = parent

    @sender = ::Admin.cubbyshop_admin
    @recipient = @parent

    @main_paragraphs = t('parenting.verify_account_reminder.email_main_paragraphs')
    @sub_paragraphs = t('parenting.verify_account_reminder.email_sub_paragraphs')
    @subject = t('parenting.verify_account_reminder.email_subject')

    mail(to: @recipient.email, subject: @subject)
  end

  ############################
  # Buying

  # +favorite_item+ <Items::FavoriteItem or Item>
  def favorite_item(favorite_item, viewer)
    @item = favorite_item.is_a?(::Item) ? favorite_item : favorite_item.item
    @user = viewer
    mail(to: @user.contact_email, subject: "#{viewer.display_name} Likes Your Item")
  end

  def is_following(following_user, shop_owner)
    @user = following_user
    mail(to: shop_owner.contact_email, subject: "#{following_user.display_name} is Following Your Shop")
  end
  
  ##
  # When a child adds an item to cart and sends message to parent to notify that he/she wants to buy.
  
  def new_buy_request(item, child)
    @user = child
    @child = child
    context_h = {child_first_name: child.first_name.titleize, child_pronoun: child.pronoun_form.titleize}
    
    @sender = ::Admin.cubbyshop_admin
    @recipient = child.parent
    
    @item = item

    @main_paragraphs = t("parenting.new_buy_request.email_main_paragraphs", context_h)
    @sub_paragraphs = t("parenting.new_buy_request.email_sub_paragraphs", context_h)
    @sub_paragraphs.each_with_index do|p, idx|
      @sub_paragraphs[idx] = p.gsub("%{child_first_name}", child.first_name.titleize).gsub("%{child_pronoun}", child.pronoun_form.titleize)
    end
    @subject = t("parenting.new_buy_request.email_subject", context_h)

    mail(to: @recipient.email, subject: @subject)
  end

  ##
  # When a buy request is accepted, an email of info is sent to the item's seller's parent.
  def new_buy_request_to_seller_parent(buy_request, item = nil)
    @buy_request = buy_request
    @user = buy_request.seller
    @child = buy_request.seller
    @item = item
    @item ||= buy_request.items.first
    context_h = {child_first_name: @child.first_name.titleize, child_pronoun: @child.pronoun_form.titleize}

    @sender = ::Admin.cubbyshop_admin
    @recipient = @child.parent

    @subject = t("parenting.new_buy_request_to_seller_parent.email_subject", context_h)

    mail(to: @recipient.email, subject: @subject)
  end

  ############################
  # Trading

  # +comment+ <ItemComment>
  def item_comment(comment)
    @item_comment = comment
    mail(to: comment.recipient.contact_email, subject: "#{comment.user.display_name} Has a Message for You")
  end

  ############################
  # Account Confirmation
  def account_confirmation_available(parent)
    @parent = parent
    child_str = parent.children.count > 1 ? "children are" : "child is"
    mail(to: parent.contact_email, subject: "Your #{child_str} ready to trade! Please verify your account.")
  end

  ############################
  # Friends

  ##
  # friend_request <Users::FriendRequest>
  # request_child <Child> The child who wants the connect to the other child 'recipient_child'
  def friend_request(friend_request, request_child, recipient_child)
    @child = request_child
    @parent = @child.parent
    @friend_request = friend_request

    ::Jobs::ApproveFriendRequestReminder.new(recipient_child.id).enqueue!

    mail(to: @parent.contact_email, subject: "Good News... #{@child.first_name.titleize} Found a Friend!")
  end

  def child_attributes(child = nil)
    child ||= @child
    { child_first_name: child.first_name.titleize, child_pronoun: child.pronoun_form.titleize,
      video_url_for_kid: ::HomeHelper::HOW_IT_WORKS_VIDEO_URL_FOR_KID,
      video_url_for_parent: ::HomeHelper::HOW_IT_WORKS_VIDEO_URL_FOR_PARENT }
  end


end
