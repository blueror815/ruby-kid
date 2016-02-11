module Geocode
  class State < ActiveRecord::Base
    self.table_name = 'country_states'
     
    attr_accessible :country_iso, :code, :name
    
    
    belongs_to :country, :class_name => '::Geocode::Country', :primary_key => :iso, :foreign_key => :country_iso
    
    scope :usa_states, where(country_iso: 'US')
    
    USA_STATE_CODES_TO_NAMES_MAP = {}
    
    usa_states.each do|state|
      USA_STATE_CODES_TO_NAMES_MAP[state.code.upcase] = state.name
    end
    
    USA_STATE_LIST = usa_states.order(:code).collect {|state| [state.name, state.code] }
    
  end
end