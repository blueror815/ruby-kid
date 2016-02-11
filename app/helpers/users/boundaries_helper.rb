module Users
  module BoundariesHelper

    def child_circle_options_for_select(user)
      list = []
      ::Users::ChildCircleOption::CIRCLE_OPTIONS_MAP.each_pair do|k, v|
        list << [v, k]
      end
      options_for_select(list, (user ? user.boundaries.child_circle_options.first.try(:content_value) : nil) )
    end

  end
end