require 'net/https'

class GtaTravelChannel < Channel

  CNAME = 'gta_travel'
  PROPERTY_READ = '/supplierapi/rest/property/search'
  PROPERTY_DETAILS_READ = '/supplierapi/rest/propertyDetails/search'
  ROOM_READ = '/supplierapi/rest/rooms/search'
  CONTRACT_READ = '/supplierapi/rest/contracts/search'
  INVENTORY_UPDATE = '/supplierapi/rest/inventory'
  INVENTORY_CREATE = '/supplierapi/rest/inventory'
  PROPERTY_RESTRICTIONS_CREATE = '/supplierapi/rest/propertyRestrictions/'
  PROPERTY_RESTRICTIONS_DELETE = '/supplierapi/rest/propertyRestrictions/delete'
  BOOKING_SEARCH = '/supplierapi/rest/bookings/search'
  STATIC_RATE_CREATE = '/supplierapi/rest/staticRates'
  MARGIN_RATE_CREATE = '/supplierapi/rest/marginRates'

  RATE_STATIC = 'static'
  RATE_MARGIN = 'margin'

  INVENTORY_SIZING = 31

  XMLNS = 'http://www.gta-travel.com/GTA/2012/05'
  XMLNS_INVENTORY_UPDATE = 'http://www.gta-travel.com/GTA/2012/05/GTA_InventoryUpdateRQ.xsd'
  XMLNS_RATE_CREATE = 'http://www.gta-travel.com/GTA/2012/05/GTA_RateCreateRQ.xsd'

  INVENTORY_FLEXIBLE_TYPE = 'Flexible'
  FREESALE_FALSE = 'false'

  CTA_TYPE_CODE = 'A'
  CTB_TYPE_CODE = 'C'

  TYPE_CONFIRMED = 'Confirmed'

  def cname
    CNAME
  end

  def inventory_handler
    GtaTravelInventoryHandler.instance
  end

  def inventory_new_room_handler
    GtaTravelInventoryNewRoomHandler.instance
  end

  def master_rate_handler
    GtaTravelMasterRateHandler.instance
  end

  def master_rate_new_room_handler
    GtaTravelMasterRateNewRoomHandler.instance
  end

  def channel_rate_handler
    GtaTravelChannelRateHandler.instance
  end

  def channel_stop_sell_handler
    GtaTravelChannelStopSellHandler.instance
  end

  def channel_min_stay_handler
    GtaTravelChannelMinStayHandler.instance
  end

  def channel_cta_handler
    GtaTravelChannelCtaHandler.new
  end

  def channel_ctb_handler
    GtaTravelChannelCtbHandler.new
  end

  def booking_handler
    GtaTravelBookingHandler.instance
  end

  def room_type_fetcher
    GtaTravelRoomTypeFetcher.instance
  end

  def success_response_checker
    GtaTravelSuccessResponseChecker.instance
  end

  def self.put_xml_change_set_channel(request_xml, change_set_channel, type)
    res = put_xml(request_xml, type)
    ChangeSetChannelLog.create(:change_set_channel_id => change_set_channel.id, :request_xml => request_xml, :response_xml => res)
    res
  end

  def self.put_xml_change_set_channel(request_xml, change_set_channel, type, fragment_id = nil)
    res = put_xml(request_xml, type)
    ChangeSetChannelLog.create(:change_set_channel_id => change_set_channel.id, :request_xml => request_xml, :response_xml => res, :fragment_id => fragment_id)
    res
  end

  def self.post_xml_change_set_channel(request_xml, change_set_channel, type)
    res = post_xml(request_xml, type)
    ChangeSetChannelLog.create(:change_set_channel_id => change_set_channel.id, :request_xml => request_xml, :response_xml => res)
    res
  end

  def self.send_request(type, hotel_key)
    uri = URI.parse(get_end_point)
    https = Net::HTTP.new(uri.host,uri.port)
    req = Net::HTTP::Get.new(uri.path)
    res = https.request(req)
    res.body
  end

  # helper to post XML to gta travel
  def self.post_xml(request_xml, type)
    uri = URI.parse(get_end_point(type))
    https = Net::HTTP.new(uri.host,uri.port)
    https.use_ssl = true
    req = Net::HTTP::Post.new(uri.path)
    req.body = request_xml
    req["Content-Type"] = "text/xml;charset=UTF-8"
    res = https.request(req)
    Rails.logger.info request_xml
    Rails.logger.info res.body
    res.body
  end

  # helper to post XML to gta travel
  def self.put_xml(request_xml, type)
    uri = URI.parse(get_end_point(type))
    https = Net::HTTP.new(uri.host,uri.port)
    https.use_ssl = true
    req = Net::HTTP::Put.new(uri.path)
    req.body = request_xml
    req["Content-Type"] = "text/xml;charset=UTF-8"
    res = https.request(req)
    Rails.logger.info request_xml
    Rails.logger.info res.body
    res.body
  end

  def self.get_all_room_type_mapping(property)
    RoomTypeChannelMapping.room_type_ids(property.room_type_ids).gta_travel_type
  end

  def self.construct_user_element(xml)
    xml.User(:Qualifier => APP_CONFIG[:gta_travel_qualifier], :UserName => APP_CONFIG[:gta_travel_username], :Password => APP_CONFIG[:gta_travel_password])
  end

  def calculate_gross(amount, margin)
    (amount * 1.0) / (1 - (margin.to_i/100))
  end

  def self.get_property_contract(property_id)
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.GTA_ContractReadRQ('xmlns' => GtaTravelChannel::XMLNS, 'xmlns:xsi' => Constant::XMLNS_XSI_2001) {
        GtaTravelChannel.construct_user_element(xml)
        xml.Property(:Id => property_id)
      }
    end

    request_xml = builder.to_xml
    GtaTravelChannel.post_xml(request_xml, GtaTravelChannel::CONTRACT_READ)
  end

  private

  def self.get_end_point(type)
    "#{APP_CONFIG[:gta_travel_endpoint]}#{type}"
  end

end
