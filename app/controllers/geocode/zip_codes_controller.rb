module Geocode
  class ZipCodesController < ApplicationController

    respond_to :js, :json
    
    # JSON format call: data of list of zip code matching locations.
    # JS/RJS call: Other than :zip, requires parameters (:city_id and :state_id) with IDs of city and state fields to update on.
    def index
      @zip_codes = ::Geocode::ZipCode.search_by_zip_code(params[:zip])
      puts "  zip codes found: #{@zip_codes.to_a}"
      respond_to do |format|
        format.js { puts "--> Autofill"; render 'autofill_city_and_state.rjs' }
        format.json { render json: @zip_codes }
      end
    end
  end
end