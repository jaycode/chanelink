require 'net/https'

class TiketcomChannel < Channel

  CNAME = 'tiketcom'

  ROOM_TYPES = 'room_types'

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
    TiketcomRoomTypeFetcher.instance
  end

  def success_response_checker
    BookingcomSuccessResponseChecker.instance
  end

  def self.post_xml_change_set_channel(request_xml, change_set_channel, type)
    res = post_xml(request_xml, type)
    ChangeSetChannelLog.create(:change_set_channel_id => change_set_channel.id, :request_xml => request_xml, :response_xml => res)
    res
  end

  def get_email_for_booking_notification(booking)
    property = booking.property
    pc = PropertyChannel.find_by_property_id_and_channel_id(property.id, self.id)
    pc.bookingcom_reservation_email_address
  end

  def self.send_request(type, hotel_key)
    puts get_end_point(type, hotel_key)
    uri = URI.parse(get_end_point(type, hotel_key))
    https = Net::HTTP.new(uri.host,uri.port)
    req = Net::HTTP::Get.new(uri.path)
    res = https.request(req)
    res.body
  end

  def self.get_all_room_type_mapping(property)
    RoomTypeChannelMapping.room_type_ids(property.room_type_ids).bookingcom_type
  end

  private

  def self.get_end_point(type, hotel_key)
    if type == ROOM_TYPES
      "http://api.tiket.com/connect/managehotel/roomtypes?hotelkey=#{hotel_key}&output=xml"
    end
  end

end
