Time::DATE_FORMATS[:short_date] = '%b %-d, %Y'
Time::DATE_FORMATS[:short_date_and_time] = '%b %-d, %Y %l:%M %p'

Time.zone = 'Eastern Time (US & Canada)'

class Regexp
  VALID_EMAIL = /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i

end

class String

  ACRONYMNS = /([a-z][\.\*,]([a-z][\.\*,])+)/i
  
  def valid_email?
    (self.to_s =~ Regexp::VALID_EMAIL) != nil
  end

  ##
  # Downcase, strip, compact in between spaces.  This way is easier to compare words only.
  # @return <String> stripped version

  def strip_naked
    return self if blank?
    self.downcase.strip.gsub(/([\s]{2,})/, ' ')
  end

  def strip_acronymns
    return self if blank?
    s2 = self.clone
    while s2 =~ ACRONYMNS; puts $1; s2.gsub!($1, $1.gsub(/[\.\*,]/,'')); end
    s2
  end

  ##
  # Wraps keywords with given pattern.
  # @param keywords <Array of String>
  # @param replacement_pattern <String, Regex replacement pattern used in gsub> or <Array like ['beginning', 'end'] >
  def highlight(keywords, replacement_pattern)
    s = self.clone
    keywords.each do|kw|
      r = replacement_pattern.is_a?(Array) ? "#{replacement_pattern.first}\\1#{replacement_pattern}" : replacement_pattern
      s.gsub!(/(#{kw})/i, replacement_pattern)
    end
    s
  end

  ##
  # Evaluate inline variables in form of "Words of %{variable_name}" and replace string with values.
  # @param map <Hash of variable name(in symbol) => value >
  def evaluate_with_variables(map)
    s = self.clone
    s.scan(/%{([\w_]+)}/ ).each do|variable_ar|
      mapped_v = map[variable_ar.first.to_sym]
      s.gsub!("%{#{variable_ar.first}}", mapped_v ) if mapped_v
    end
    s
  end
end

class Fixnum

  ##
  # @return <String> Hex/16-based value with 0 prefixed if it's only single digit.
  def to_full_hex
    chars = self.to_s(16)
    (chars.size == 1) ? '0' + chars : chars
  end
end