module Users
  module IsPrimary

    def self.included(mod)
      mod.scope :primary, mod.where(is_primary: true)

      mod.before_save :set_primary!
    end
    
    def set_primary!

      self.is_primary = false if self.is_primary.nil? # DB schema's boolean field default value is questionable

      primary_ones = self.class.where(user_id: user_id).primary
      if primary_ones.empty?
        self.is_primary = true

      else # Another address of primary already set

        if self.is_primary
          puts ">> Set address #{self} to PRIMARY (changed? #{self.changed?})"
          self.class.update_all(["is_primary = false"], ["user_id = ? and is_primary = true and id != ?", user_id, id])
        else
          self.is_primary = false
        end
      end
      true
    end

  end
end