module Users
  module Notifications
    class TradeBasic < ::Users::Notification

      before_create :cleanup_trade_notifications!
      ###after_create :update_trade_info!

      ##
      # Shortcut to create similar notification based on trade.
      # @sender <User or user.id>
      def initialize(trade, sender, options = {})
        opts = options.clone
        uri = Rails.application.routes.url_helpers.trade_path(trade)
        user_id = sender.is_a?(User) ? sender.id : sender.to_i
        opts.merge!( sender_user_id: user_id,
                     uri: uri, related_model_type: trade.class.to_s, related_model_id: trade.id )

        opts[:recipient_user_id] = trade.the_other_user(user_id).id if options[:recipient_user_id].blank?
        super( opts )
      end

      def self.create(trade, sender, options = {})
        n = new(trade, sender, options)
        n.save
        n
      end

      def is_sender_the_merchant?
        trade = self.related_model
        return false if trade.nil?
        (trade.seller_id == sender_user_id)
      end

      def starred
        true
      end

      def context_specific_notification_text
        context_notification_text = super
        trade = self.related_model
        return context_notification_text if trade.nil?
        user_id = sender.is_a?(User) ? sender.id : sender.to_i
        context_notification_text['%{the_other_user}'] = trade.the_other_user(self.recipient).user_name
        context_notification_text['%{the_other_user_name}'] = trade.the_other_user(self.recipient).display_name.titleize
        context_notification_text['%{buyer}'] = trade.buyer.user_name
        context_notification_text['%{seller}'] = trade.seller.user_name
        context_notification_text['%{buyer_parent_rel}'] = trade.buyer.parent.informal_relationship_to(trade.buyer) if trade.buyer.parent
        context_notification_text['%{seller_parent_rel}'] = trade.seller.parent.informal_relationship_to(trade.seller) if trade.seller.parent
        context_notification_text
      end

      def get_type
        :trade
      end

      alias_method :trade, :related_model

      def action_icon
        'trade'
      end

      protected

      def update_trade_info!
        if trade.both_sides_have_items? && self.starred
          trade.update_attribute(:waiting_for_user_id, trade.the_other_user(sender).id )

        end
      end

      ##
      # Each trade only needs one notification for that user depending on its most recent status
      def cleanup_trade_notifications!
        if self.related_model_type =~ /Trading::Trade/
          ::Users::Notification.delete_all(recipient_user_id: self.recipient_user_id, related_model_type: self.related_model_type, related_model_id: self.related_model_id )
        end
      end

    end
  end
end
