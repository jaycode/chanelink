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
  

  # CtripBookings
  soap_action "CtripBookings",
    :args   => {
      :channel     => {
        :username     => :string,
        :password     => :string,
        :hotel_id     => :string,
        :code_context => :string
      },
      :bookings => [{
        :rate_plan_code     => :string,
        :rate_plan_category => :string,
        :guest_name         => :string,
        :date_start         => :string,
        :date_end           => :string,
        :booking_date       => :string,
        :total_rooms        => :integer,
        :amount             => :double,
        :ctrip_booking_id   => :string
      }]
    },
    :return => {
      :response => {
        :status   => :string,
        :message  => :string
      },
    },
    :to     => :ctrip_bookings

  def ctrip_bookings
    # render :soap => params[:bookings][1][:rate_plan_code]
    status        = 'failed'
    message       = 'Invalid channel data!'

    # get ctrip property by :channel params
    Property.active_only.each do |property|
      settings = property.settings
      if settings['ctrip_username'] == params[:channel][:username] && settings['ctrip_password'] == params[:channel][:password] && settings['ctrip_hotel_id'] == params[:channel][:hotel_id] && settings['ctrip_code_context'] == params[:channel][:code_context]
        status  = 'success'
        message = 'Chanelink inventory updated!'

        #step 1, validate data from ctrip
        validate = true

        #step 2, process all data with booking handler and inventory handler
        if validate
          property.channels.each do |pc|
            pc.channel.booking_handler.retrieve_and_process_by_bookings_data(params[:bookings], property) if pc.channel == CtripChannel.first
          end
        end

      end
    end

    render :soap => {
      :response => {
        :status   => status,
        :message  => message,
      }
    }
  end

end