class ApiController < ApplicationController
  soap_service namespace: 'API:Chanelink'
  
  # # Simple case
  # soap_action "book",
  #   :args => {
  #     :channel    => :string,
  #     :hotel_id   => :string,
  #     :rate_plan  => :string,
  #     :nights     => :integer
  #   },
  #   :return => :string

  # def book
  #   render :soap => params[:channel]
  # end

  # Bookings
  soap_action "Bookings",
    :args => {
      :channel    => {
        :code     => :integer,
        :username => :string,
        :password => :string
      },
      :hotels     => [
        :hotel => {
          :code           => :string,
          :category       => :string,
          :rate           => :double,
          :currency_code  => :string,
          :start_date     => :string,
          :end_date       => :string,
          :rooms          => :integer
        }
      ]
    },
    :return => {
      :status     => :string,
      :trans_code => :string,
      :date       => :string
    },
    :to     => :bookings
  def bookings
    render :soap => {
      :status     => 'success',
      :trans_code => 'IA123POK',
      :date       => '19/05/2015 18:04 WIB'  
    }
  end

end