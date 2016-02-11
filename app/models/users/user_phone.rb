
module Users
  class UserPhone < ActiveRecord::Base
    
    self.table_name = 'user_phones'
    
    attr_accessible :number, :phone_type, :user_id, :is_primary
    
    include IsPrimary
    
    belongs_to :user

    scope :primary, where(is_primary: true)
    
    object_constants :phone_type, :home, :mobile, :work
    
    validates_presence_of :number
    validates_format_of :number, with: /[\d]{3,4}[\s\-]?[\d]{4}[\w\s]*/


    # If there is a record with is_primary=true, replace that one.  Otherwise create new primary.
    # attributes <Hash of ::Users::UserPhone attributes>
    def self.set_primary_for_user!(user, attributes = {})
      if attributes.present?
        current_primary = user.user_phones.find{|ph| ph.is_primary }
        current_primary ||= user.user_phones.first || new(is_primary: true)
        current_primary.attributes = attributes
        current_primary.user_id ||= user.id
        current_primary.save
      end
    end

    def as_json(options = {})
      super( only: [:number, :phone_type, :user_id, :is_primary] )
    end
  end
end