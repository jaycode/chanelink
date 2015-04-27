require 'net/https'

class OrbitzChannel < Channel

  CNAME = 'orbitz'
  XMLNS = 'http://www.opentravel.org/OTA/2003/05'

  # Todo: Move the following to default_settings
  TYPE4_USERNAME = 'Chanelink'
  TYPE4_PASSWORD = '8bd6f6c'
  TYPE10_USERNAME = 'CLink'
  TYPE10_PASSWORD = 'Ecc579$'
  ROOM_RATE_FETCH = 'room_rate_fetch'
  OTHER = 'other'
  SINGLE = 'Single'
  DOUBLE = 'Double'
  TRIPLE = 'Triple'
  QUAD = 'Quad'
  SIZING = 5

  def cname
    CNAME
  end

  def inventory_handler
    OrbitzInventoryHandler.instance
  end

  def inventory_new_room_handler
    OrbitzInventoryNewRoomHandler.instance
  end

  def master_rate_handler
    OrbitzMasterRateHandler.instance
  end

  def master_rate_new_room_handler
    OrbitzMasterRateNewRoomHandler.instance
  end

  def channel_rate_handler
    OrbitzChannelRateHandler.instance
  end

  def channel_stop_sell_handler
    OrbitzChannelStopSellHandler.instance
  end

  def channel_min_stay_handler
    OrbitzChannelMinStayHandler.instance
  end

  def channel_cta_handler
    OrbitzChannelCtaHandler.instance
  end

  def channel_ctd_handler
    OrbitzChannelCtdHandler.instance
  end

  def booking_handler
    OrbitzBookingHandler.instance
  end

  def room_type_fetcher
    OrbitzRoomTypeFetcher.instance
  end

  def success_response_checker
    OrbitzSuccessResponseChecker.instance
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

  def self.construct_auth_element(xml)
    xml.POS {
      xml.Source {
        xml.RequestorID(:ID => TYPE4_USERNAME, :MessagePassword => TYPE4_PASSWORD, :Type => "4")
      }
      xml.Source {
        xml.RequestorID(:ID => TYPE10_USERNAME, :MessagePassword => TYPE10_PASSWORD, :Type => "10")
      }
    }
  end

  # helper to post XML to gta travel
  def self.post_xml(request_xml, type)
    uri = URI.parse(get_end_point(type))
    https = Net::HTTP.new(uri.host,uri.port)
    https.use_ssl = true
    req = Net::HTTP::Post.new(uri.path)
    req.basic_auth(TYPE4_USERNAME, TYPE4_PASSWORD)
    req.body = request_xml
    req["Content-Type"] = "text/xml;charset=UTF-8"
    res = https.request(req)
    puts request_xml
    puts res.body
    res.body
  end

  def self.get_property_contract(property_channel)

    # construct xml to request room type list
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.OWW_HotelRoomRatePlanGetRQ(:xmlns => OrbitzChannel::XMLNS) {
        OrbitzChannel.construct_auth_element(xml)
        xml.RoomRatePlan {
          xml.HotelCriteria(:ChainCode => property_channel.orbitz_chain_code, :HotelCode => property_channel.orbitz_hotel_code)
        }
      }
    end

    request_xml = builder.to_xml
    OrbitzChannel.post_xml(request_xml, OrbitzChannel::ROOM_RATE_FETCH)
  end

  # calculate single rate for room type mapping
  def self.calculate_single_rate(room_type_channel_mapping, amount = 0)
    multiplier = 1.0

    if !room_type_channel_mapping.orbitz_single_rate_multiplier.blank?
      multiplier = room_type_channel_mapping.orbitz_single_rate_multiplier
    end

    multiplier * amount
  end

  # calculate double rate for room type mapping
  def self.calculate_double_rate(room_type_channel_mapping, amount = 0)
    multiplier = 1.0

    if !room_type_channel_mapping.orbitz_double_rate_multiplier.blank?
      multiplier = room_type_channel_mapping.orbitz_double_rate_multiplier
    end

    multiplier * amount
  end

  # calculate single rate for room type mapping
  def self.calculate_triple_rate(room_type_channel_mapping, amount = 0)
    multiplier = 1.0

    if !room_type_channel_mapping.orbitz_triple_rate_multiplier.blank?
      multiplier = room_type_channel_mapping.orbitz_triple_rate_multiplier
    end

    multiplier * amount
  end

  # calculate double rate for room type mapping
  def self.calculate_quad_rate(room_type_channel_mapping, amount = 0)
    multiplier = 1.0

    if !room_type_channel_mapping.orbitz_quad_rate_multiplier.blank?
      multiplier = room_type_channel_mapping.orbitz_quad_rate_multiplier
    end

    multiplier * amount
  end

  private

  def self.get_end_point(type)
    if type == ROOM_RATE_FETCH
      APP_CONFIG[:orbitz_room_rate_fetch]
    else
      APP_CONFIG[:orbitz_other]
    end
  end

end
