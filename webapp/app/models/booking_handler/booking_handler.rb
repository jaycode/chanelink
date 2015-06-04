require 'singleton'

# class to retrieve and store booking from OTA
class BookingHandler
  include Singleton

  def retrieve_and_process(property)
    # do nothing, to be overridden by sub class
  end

  def retrieve_and_process_by_bookings_data(bookings_data, property)
  	# do nothing, to be overridden by sub class
  end
end
