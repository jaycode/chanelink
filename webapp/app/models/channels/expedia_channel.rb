require 'net/https'

# class representing expedia channel
class ExpediaChannel < Channel

  CNAME = 'expedia'
  # Todo: Remove this, it has no importance to interface.
  XMLNS_AR = 'http://www.expediaconnect.com/EQC/AR/2011/06'
  XMLNS_BR = 'http://www.expediaconnect.com/EQC/BR/2007/02'
  XMLNS_BR_2014 = 'http://www.expediaconnect.com/EQC/BR/2014/01'
  XMLNS_BC = 'http://www.expediaconnect.com/EQC/BC/2007/09'
  XMLNS_PAR = 'http://www.expediaconnect.com/EQC/PAR/2013/07'

  AR = 'ar'
  BR = 'br'
  BC = 'bc'
  PARR = 'parr'

  RATE_SIZING = 150
  MASTER_RATE_SIZING = 50
  MASTER_RATE_NEW_ROOM_SIZING = 150
  MIN_STAY_SIZING = 150
  CTA_SIZING = 150
  CTD_SIZING = 150

  def cname
    CNAME
  end

  def inventory_handler
    ExpediaInventoryHandler.instance
  end

  def inventory_new_room_handler
    ExpediaInventoryNewRoomHandler.instance
  end

  def master_rate_handler
    ExpediaMasterRateHandler.instance
  end

  def master_rate_new_room_handler
    ExpediaMasterRateNewRoomHandler.instance
  end

  def channel_rate_handler
    ExpediaChannelRateHandler.instance
  end

  def channel_stop_sell_handler
    ExpediaChannelStopSellHandler.instance
  end

  def channel_min_stay_handler
    ExpediaChannelMinStayHandler.instance
  end

  def booking_handler
    ExpediaBookingHandler.instance
  end

  def channel_cta_handler
    ExpediaChannelCtaHandler.new
  end

  def channel_ctd_handler
    ExpediaChannelCtdHandler.new
  end

  def room_type_fetcher
    ExpediaRoomTypeFetcher.instance
  end

  def success_response_checker
    ExpediaSuccessResponseChecker.instance
  end

  # get the email customer nominated as address to receiver booking news
  def get_email_for_booking_notification(booking)
    email = nil
    property = booking.property
    pc = PropertyChannel.find_by_property_id_and_channel_id(property.id, self.id)

    # email address is different for new, modify, and cancel
    if booking.type_new?
      email = pc.expedia_reservation_email_address
    elsif booking.type_modify?
      email = pc.expedia_modification_email_address
    elsif booking.type_cancel?
      email = pc.expedia_cancellation_email_address
    end
    email
  end

  # pust XML to Expedia
  def self.post_xml_change_set_channel(request_xml, change_set_channel, type, fragment_id = nil)
    res = post_xml(request_xml, type)
    ChangeSetChannelLog.create(:change_set_channel_id => change_set_channel.id, :request_xml => request_xml, :response_xml => res, :fragment_id => fragment_id)
    res
  end

  # helper to post XML to expedia
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

  # get currency specified for expedia
  def self.get_currency(property_channel)
    property_channel.expedia_currency
  end

  # get all room type mapping from a property to expedia
  def self.get_all_room_type_mapping(property)
    RoomTypeChannelMapping.room_type_ids(property.room_type_ids).expedia_type
  end

  private

  # end point to push XML to expedia
  def self.get_end_point(type)
    if type == AR
      APP_CONFIG[:expedia_ar_endpoint]
    elsif type == BR
      APP_CONFIG[:expedia_br_endpoint]
    elsif type == BC
      APP_CONFIG[:expedia_bc_endpoint]
    elsif type == PARR
      APP_CONFIG[:expedia_parr_endpoint]
    end
  end

end
