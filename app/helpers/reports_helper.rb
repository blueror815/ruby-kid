module ReportsHelper

  def make_reason_type_select_options
    list = []
    (auth_user.is_a?(Parent) ? ::Report::REASON_TYPES_PARENT : ::Report::REASON_TYPES_CHILD).each_pair do|value, title|
      list << [title, value]
    end
    list
  end

end
