class Device < ActiveRecord::Base
  attr_accessible :type, :push_token

  validates_uniqueness_of :push_token

  belongs_to :user

  before_save :sanitize_attributes

  def as_json(options = {} )
    type_simplified = self.type.to_s.split('::').last.underscore.downcase
    super(options).merge(type: type_simplified)
  end

  private

  def sanitize_attributes
    if self.type.present?
      if self.type.starts_with?('Devices::')
        self.type = self.type.camelize
      else
        self.type = "Devices::#{self.type.camelize}"
      end
    end
  end
end
