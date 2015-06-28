require 'net/https'

# class represent agoda channel
class AgodaChannel < Channel

  CNAME = 'agoda'
  XMLNS = 'http://xml.ycs.agoda.com'
  SUCCESS_CODE = '200'
  DEFAULT_RATE_PLAN_ID = '1'
  API_KEY = 'b9df91e4-e7dc-4293-a7f8-a633b27bc1e3'

  def cname
    CNAME
  end

  def inventory_handler
    AgodaInventoryHandler.instance
  end

  def inventory_new_room_handler
    AgodaInventoryNewRoomHandler.instance
  end

  def master_rate_handler
    AgodaMasterRateHandler.instance
  end

  def master_rate_new_room_handler
    AgodaMasterRateNewRoomHandler.instance
  end

  def channel_rate_handler
    AgodaChannelRateHandler.instance
  end

  def channel_stop_sell_handler
    AgodaChannelStopSellHandler.instance
  end

  def channel_min_stay_handler
    AgodaChannelMinStayHandler.instance
  end

  def channel_cta_handler
    AgodaChannelCtaHandler.new
  end

  def channel_ctd_handler
    AgodaChannelCtdHandler.new
  end

  def booking_handler
    AgodaBookingHandler.instance
  end

  def rate_type_fetcher
    AgodaRateTypeFetcher.instance
  end

  def room_type_fetcher
    AgodaRoomTypeFetcher.instance
  end

  def success_response_checker
    AgodaSuccessResponseChecker.instance
  end

  # utility method to post given xml
  def self.post_xml_change_set_channel(request_xml, change_set_channel)
    res = post_xml(request_xml)
    ChangeSetChannelLog.create(:change_set_channel_id => change_set_channel.id, :request_xml => request_xml, :response_xml => res)
    res
  end

  # helper class to post xml
  def self.post_xml(request_xml)
    uri = URI.parse(APP_CONFIG[:agoda_endpoint])
    https = Net::HTTP.new(uri.host,uri.port)
    # Using ssl even in development and test so Agoda may work still.
    # https.use_ssl = true if Rails.env.production?
    https.use_ssl = true
    req = Net::HTTP::Post.new(uri.path)
    req.body = request_xml
    res = https.request(req)
    res.body
  end

  # calculate single rate for room type mapping
  def self.calculate_single_rate(room_type_channel_mapping, amount = 0)
    multiplier = 1.0

    if !room_type_channel_mapping.agoda_single_rate_multiplier.blank?
      multiplier = room_type_channel_mapping.agoda_single_rate_multiplier
    end

    multiplier * amount
  end

  # calculate double rate for room type mapping
  def self.calculate_double_rate(room_type_channel_mapping, amount = 0)
    multiplier = 1.0

    if !room_type_channel_mapping.agoda_double_rate_multiplier.blank?
      multiplier = room_type_channel_mapping.agoda_double_rate_multiplier
    end

    multiplier * amount
  end

  # calculate full rate for room type mapping
  def self.calculate_full_rate(room_type_channel_mapping, amount = 0)
    multiplier = 1.0

    if !room_type_channel_mapping.agoda_full_rate_multiplier.blank?
      multiplier = room_type_channel_mapping.agoda_full_rate_multiplier
    end

    multiplier * amount
  end

  # get extra bed for a room type mapping
  def self.get_extra_bed(room_type_channel_mapping)
    result = 0

    if !room_type_channel_mapping.agoda_extra_bed_rate.blank?
      result = room_type_channel_mapping.agoda_extra_bed_rate
    end

    result
  end

  # get currency for a channel mapping
  def self.get_currency(property_channel)
    property_channel.agoda_currency
  end

  # get all room type mapping from a property to agoda
  def self.get_all_room_type_mapping(property)
    RoomTypeChannelMapping.room_type_ids(property.room_type_ids).agoda_type
  end

end
