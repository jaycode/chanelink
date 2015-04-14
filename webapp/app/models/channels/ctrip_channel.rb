require 'net/https'

class CtripChannel < Channel

  CNAME = 'ctrip'
  XMLNS = 'http://www.opentravel.org/OTA/2003/05'

  API_VERSION = "2.2"
  PRIMARY_LANG = 'en-us'

  RATE_PLAN = 'rate_plan'
  AVAIL_NOTIF = 'avail_notif'
  RATE_AMOUNT_NOTIF = 'rate_amount_notif'
  NOTIF_REPORT = 'notif_report'

  # 10 is for individual hotel (see Ctrip Integration API Specification V2.2.pdf)
  USER_CATEGORY = 10

  COMPANY_CODE = 'C'

  def cname
    CNAME
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

  def room_type_fetcher
    CtripRoomTypeFetcher.instance
  end

  def success_response_checker
    CtripSuccessResponseChecker.instance
  end

  def self.post_xml_change_set_channel(request_xml, change_set_channel, type)
    res = post_xml(request_xml, type)
    ChangeSetChannelLog.create(:change_set_channel_id => change_set_channel.id, :request_xml => request_xml, :response_xml => res)
    res
  end

  # helper class to post xml
  def self.post_xml(request_xml, type)
    # puts "END POINT #{get_end_point}"
    # puts request_xml

    # uri = URI.parse(get_end_path(type))
    # http = Net::HTTP.new(uri.host,uri.port)
    # http.use_ssl = false
    # path = get_end_path(type)

    # puts path

    # # Set Headers
    # headers = {
    #   'Content-Type' => 'text/xml',
    #   'Host' => uri.host,
    #   'SOAPAction' => "http://www.opentravel.org/OTA/2003/05/Request"
    # }

    # # Post the request
    # resp, data = http.post(path, request_xml, headers)

    # puts resp

    # data

    uri = URI.parse("http://58.221.127.196:8090/Hotel/OTAReceive/HotelRatePlan.asmx")
    https = Net::HTTP.new(uri.host,uri.port)
    https.use_ssl = false

    req = Net::HTTP::Post.new(uri.path)
    req["Content-Type"] = 'text/xml'
    req["Host"] = uri.host

    req.body = request_xml
    res = https.request(req)

    puts res.body

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
        xml.RequestorID(:ID => property.settings(:ctrip_username), :MessagePassword => property.settings(:ctrip_password), :Type => USER_CATEGORY) {
          xml.CompanyName(:Code => COMPANY_CODE, :CodeContext => property.settings(:ctrip_code_context))
        }
      }
    }
  end

  private

  def self.get_end_point
    APP_CONFIG[:ctrip_end_point]
  end

  def self.get_end_path(type)
    if type == RATE_PLAN
      APP_CONFIG[:ctrip_rate_plan]
    elsif type == AVAIL_NOTIF
      APP_CONFIG[:ctrip_avail_notif]
    elsif type == RATE_AMOUNT_NOTIF
      APP_CONFIG[:ctrip_rate_amount_notif]
    elsif type == NOTIF_REPORT
      APP_CONFIG[:ctrip_notif_report]
    end
  end


end
