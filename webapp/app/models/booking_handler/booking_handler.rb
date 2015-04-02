require 'singleton'

# class to retrieve and store booking from OTA
class BookingHandler
  include Singleton

  def retrieve_and_process(property)
    # do nothing, to be overridden by sub class
  end

end
