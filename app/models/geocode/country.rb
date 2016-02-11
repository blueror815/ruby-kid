module Geocode
  class Country < ActiveRecord::Base
   
    attr_accessible :iso, :iso3, :name, :printable_name, :numcode
    
    has_many :states, :class_name => '::Geocode::State', :foreign_key => :country_iso
    
    scope :country_usa, where(:iso => 'US')
    
    USA = country_usa.first
    
  end
end