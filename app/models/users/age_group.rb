module Users
  class AgeGroup
    attr_accessor :name, :range

    def initialize(attributes = {})
      self.name = attributes[:name]
      self.range = attributes[:range]
    end

    AGE_GROUPS = [
        AgeGroup.new(name: 'Infant', range: 0 .. 1),
        AgeGroup.new(name: 'Toddler', range: 2 .. 4),
        AgeGroup.new(name: 'Youth', range: 5 .. 10),
        AgeGroup.new(name: 'Teen', range: 11 .. 17)
        #AgeGroup.new(name: 'Young Adult', range: 18 .. 29),
        #AgeGroup.new(name: 'Mid-age Adult', range: 30 .. 59),
        #AgeGroup.new(name: 'Senior', range: 60 .. 150)
    ]


    def self.matching_age_group(age_or_birthdate)
      age = age_or_birthdate.is_a?(Date) ? ((Date.today - age_or_birthdate) / 365.25).to_i : age_or_birthdate.to_i
      group = AGE_GROUPS.find { |g| g.range.include?(age) }
      group ||= AGE_GROUPS.last
      group
    end
    
    ##
    # @return <String> either in numeric range like '1 - 3' or partially worded like '2 & Under'
    def self.age_group_name(age_group)
      age_group = '' if age_group.blank?
      if age_group == '0-1'
        '2 & Under'
      elsif age_group =~ /^(\d+)\s*\-\s*$/
        "#{$1} & Up"
      elsif age_group =~ /^(\d+)\s*\-\s*(\d+)$/
        ( $1.to_i == 0 ) ? "#{$2} & Under" : "#{$1} - #{$2}"
      else
        'All Ages'
      end
    end
    
    # Instead of name, generates the range in words like '2 to 4'
    def self.range_in_words(range)
      if range == (0 .. 1)
        'Under 1'
      elsif range.begin == 60
        '60 or Older'
      else
        "#{range.begin} to #{range.end}"
      end
    end

    # intended_age_group <String>
    # return <Integer> could be nil, meaning all ages
    def self.intended_age_group_to_difference(intended_age_group)
      intended_ag = intended_age_group.to_s.downcase # normalize
      age_group_diff = nil
      if intended_ag == 'same'
        age_group_diff = 0
      elsif intended_ag == 'younger'
        age_group_diff = -1
      elsif intended_ag == 'older'
        age_group_diff = 1
      end
      age_group_diff
    end

    # return <integer> could be nil
=begin
    def self.intended_age_group_to_age_group(current_user, intended_age_group)
      age_group = nil
      if (age_group_diff = intended_age_group_to_difference(intended_age_group) )
        relative_ag_index = nil
        AGE_GROUPS.each_with_index do|ag, index|
          if ag.range.include?( current_user.age ) ######### actually there's no user.age cuz that'd need standardized mapping of grade to age
            relative_ag_index = index + age_group_diff
          end
        end
        if relative_ag_index && relative_ag_index >= 0 && relative_ag_index < AGE_GROUPS.size
          age_group = AGE_GROUPS[relative_ag_index]
        end
      end
      age_group
    end
=end

    ##
    # return <Array of AgeGroup>
    def self.make_relative_age_groups(age)

    end
  end
end