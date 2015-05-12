class Api::SoapController < ApplicationController
  soap_service namespace: 'API:Chanelink'
  # Simple case
  soap_action "book",
              :args   => {
                :channel => :string,
                :hotel_id => :string,
                :rate_plan => :string,
                :nights => :int},
              :return => :string
  def book
    render :soap => params[:value].to_s
  end

end