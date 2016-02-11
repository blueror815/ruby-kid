module Users
  module Notifications
    class ChildReported < ::Users::Notification

      after_create :create_email!

      def copy_identifier
        :report_child_reported
      end

      def starred
        @report ||= related_model
        @report.is_a?(::Report) ? @report.pending_parent_action? : true
      end

      def context_specific_notification_text
        context_notification_text = super
        @report ||= related_model
        if @report.is_a?(::Report)
          context_notification_text['%{content_type_name}'] = @report.content_type_name
        end
        context_notification_text
      end


      protected

      def set_defaults
        super
        self.uri = Rails.application.routes.url_helpers.report_path(id: related_model_id)
      end

      def create_email!
        @report ||= related_model
        ::NotificationMail.create_from_mail(::Admin.cubbyshop_admin.id, self.recipient_user_id, UserMailer.child_reported(@report), 'child_reported', related_model_id)
      end
    end
  end
end