require 'net/https'

# represent booking.com channel
class BookingcomChannel < Channel

  CNAME = 'bookingcom'

  # Todo: Remove this, it has no importance to interface.
  ROOMS = 'rooms'
  ROOM_RATES = 'roomrates'
  RATES = 'rates'
  AVAILABILITY = 'availability'
  RESERVATIONS = 'reservations'

  USERNAME = 'ChanelinkXML'
  PASSWORD = 'kQ2Bt9g2'

  def cname
    CNAME
  end

  def inventory_handler
    BookingcomInventoryHandler.instance
  end

  def inventory_new_room_handler
    BookingcomInventoryNewRoomHandler.instance
  end

  def master_rate_handler
    BookingcomMasterRateHandler.instance
  end

  def master_rate_new_room_handler
    BookingcomMasterRateNewRoomHandler.instance
  end

  def channel_rate_handler
    BookingcomChannelRateHandler.instance
  end

  def channel_stop_sell_handler
    BookingcomChannelStopSellHandler.instance
  end

  def channel_min_stay_handler
    BookingcomChannelMinStayHandler.instance
  end

  def channel_cta_handler
    BookingcomChannelCtaHandler.new
  end

  def channel_ctd_handler
    BookingcomChannelCtdHandler.new
  end

  def booking_handler
    BookingcomBookingHandler.instance
  end

  def room_type_fetcher
    BookingcomRoomTypeFetcher.instance
  end

  def success_response_checker
    BookingcomSuccessResponseChecker.instance
  end

  # handle posting xml to booking.com
  def self.post_xml_change_set_channel(request_xml, change_set_channel, type)
    res = post_xml(request_xml, type)
    ChangeSetChannelLog.create(:change_set_channel_id => change_set_channel.id, :request_xml => request_xml, :response_xml => res)
    res
  end

  # get email that customer nominate as the address to receive new booking
  def get_email_for_booking_notification(booking)
    property = booking.property
    pc = PropertyChannel.find_by_property_id_and_channel_id(property.id, self.id)
    pc.bookingcom_reservation_email_address
  end

  # helper to post XML to booking.com
  def self.post_xml(request_xml, type)
    puts get_end_point(type)
    uri = URI.parse(get_end_point(type))
    https = Net::HTTP.new(uri.host,uri.port)
    https.use_ssl = true
    req = Net::HTTP::Post.new(uri.path)
    req.body = request_xml
    res = https.request(req)
    res.body
  end

  # get all room type mapping from a property to booking.com
  def self.get_all_room_type_mapping(property)
    RoomTypeChannelMapping.room_type_ids(property.room_type_ids).bookingcom_type
  end

  private

  # end point for pushing booking.com XML
  def self.get_end_point(type)
    if type == ROOMS
      'https://supply-xml.booking.com/hotels/xml/rooms'
    elsif type == RATES
      'https://supply-xml.booking.com/hotels/xml/rates'
    elsif type == ROOM_RATES
      'https://supply-xml.booking.com/hotels/xml/roomrates'
    elsif type == AVAILABILITY
      'https://supply-xml.booking.com/hotels/xml/availability'
    elsif type == RESERVATIONS
      'https://secure-supply-xml.booking.com/hotels/xml/reservations'
    end
  end

end
