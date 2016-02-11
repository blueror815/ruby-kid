module Users
  module Notifications
    class ReportedChild < ChildReported

      def copy_identifier
        :report_reported_child
      end

    end
  end
end
