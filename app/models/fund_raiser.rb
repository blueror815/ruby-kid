class FundRaiser < ::ActiveRecord::Base

  attr_accessible :name, :email, :school_name, :city_state

  validates_presence_of :name, :email, :school_name, :city_state

end