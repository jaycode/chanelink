require 'singleton'

# class to retrieve and store booking from OTA
class BookingHandler
  include Singleton

  # days: How many days in the past?
  def get_bookings(property, days)
    bookings = Array.new
    get_bookings_xml(property, days) do |xml_doc|
      bookings = parse_booking_details_and_store(xml_doc, property)
    end
    bookings
  end

  def get_bookings_xml(property, days)
    # To be overriden by sub class
  end

  def parse_booking_details_and_store(xml_doc, property)
    # To be overridden by sub class
  end

  def retrieve_and_process(property)
    # do nothing, to be overridden by sub class
  end

  def retrieve_and_process_by_bookings_data(bookings_data, property)
  	# do nothing, to be overridden by sub class
  end
end
