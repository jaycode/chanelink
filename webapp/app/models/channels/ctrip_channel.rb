require 'net/https'

# Todo: Not all classes need to be Model. In this case, 
#       Channels may better be left as Model-less Ruby Class,
#       Since it doesn't really need database, now does it?
# Todo: Currently this class is externally dependant to app_config.yml,
#       not sure if it is the best way forward but let's think about this
#       after we have detached it from database.
class CtripChannel < Channel

  CNAME = 'ctrip'
  XMLNS = 'http://www.opentravel.org/OTA/2003/05'
  XMLNS_XSI = 'http://www.w3.org/2001/XMLSchema-instance'
  XMLNS_XSD = 'http://www.w3.org/2001/XMLSchema'
  SOAP_ACTION = 'http://www.opentravel.org/OTA/2003/05/Request'
  SOAP_ENV = 'http://schemas.xmlsoap.org/soap/envelope/'

  API_VERSION = "2.2"
  PRIMARY_LANG = 'en-us'

  CATEGORY_MAPPING = {
    '501' => 'Prepay',
    '16' => 'Pay at hotel'
  }

  # These will be passed to Property's settings. The reason we put them here is
  # so it is easier if later the OTA should decide to make a setting dynamic, e.g.
  # what if Ctrip company code can be set differently per each user?
  # Secondly it acts as a quick way of documenting what options should settings field have.
  def default_settings
    {
      :ctrip_username => '',
      :ctrip_password => '',
      :ctrip_hotel_id => '',
      :ctrip_code_context => '',

      :ctrip_company_code => 'C',

      # 10 is for Channel Manager (see Ctrip Integration API Specification V2.2.pdf)
      # While 1 is for indifidual hotel.
      :ctrip_user_category => 10
    }
  end

  def room_type_name(channel_room_type)
    pay_type = CtripChannel::CATEGORY_MAPPING[channel_room_type.rate_plan_category]
    "#{channel_room_type.name.sub('(pay at hotel)', '').sub('pre-pay', '')} (#{pay_type}) - #{channel_room_type.id}"
  end

  def cname
    CNAME
  end

  def asynchronous_handler
    CtripChannelAsynchronousHandler.instance
  end

  def inventory_handler
    CtripInventoryHandler.instance
  end

  def inventory_new_room_handler
    CtripInventoryNewRoomHandler.instance
  end

  def master_rate_handler
    CtripMasterRateHandler.instance
  end

  def master_rate_new_room_handler
    CtripMasterRateNewRoomHandler.instance
  end

  def channel_rate_handler
    CtripChannelRateHandler.instance
  end

  def channel_stop_sell_handler
    CtripChannelStopSellHandler.instance
  end

  def channel_min_stay_handler
    CtripChannelMinStayHandler.instance
  end

  def channel_cta_handler
    #do nothing
  end

  def channel_ctd_handler
    #do nothing
  end

  def booking_handler
    CtripBookingHandler.instance
  end

  def rate_type_fetcher
    CtripRateTypeFetcher.instance
  end

  def room_type_fetcher
    CtripRoomTypeFetcher.instance
  end

  def success_response_checker
    CtripSuccessResponseChecker.instance
  end

  def self.post_xml_change_set_channel(request_xml, change_set_channel, uri)
    res = post_xml(request_xml, uri)
    ChangeSetChannelLog.create(:change_set_channel_id => change_set_channel.id, :request_xml => request_xml, :response_xml => res)
    res
  end

  # helper class to post xml
  def self.post_xml(request_xml, uri)
    uri = URI.parse(uri)
    https = Net::HTTP.new(uri.host,uri.port)
    https.use_ssl = false

    req = Net::HTTP::Post.new(uri.path)
    req["Content-Type"] = 'text/xml'
    req["Host"] = uri.host
    req["SoapAction"] = self::SOAP_ACTION

    req.body = request_xml
    res = https.request(req)

    res.body
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

  def self.construct_authentication_element(xml, property)
    xml.POS {
      xml.Source {
        xml.RequestorID(:ID => property.settings(:ctrip_username), :MessagePassword => property.settings(:ctrip_password), :Type => property.settings(:ctrip_user_category)) {
          xml.CompanyName(:Code => property.settings(:ctrip_company_code), :CodeContext => property.settings(:ctrip_code_context))
        }
      }
    }
  end
end
