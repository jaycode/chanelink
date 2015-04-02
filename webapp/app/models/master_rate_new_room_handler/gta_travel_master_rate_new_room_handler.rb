require 'net/https'

# handler to push XML to Agoda because of new room type mapping created using master rate
class GtaTravelMasterRateNewRoomHandler < MasterRateHandler

  def run(change_set_channel)
    change_set = change_set_channel.change_set

    # get the property of this change set
    property = change_set.logs.first.master_rate.property
    property_channel = property.channels.find_by_channel_id(channel.id)
    pool = change_set.pool
    room_type_channel_mapping = change_set.room_type_channel_mapping
    room_type = room_type_channel_mapping.room_type
    master_room_type = RoomType.find(change_set.logs.first.master_rate.room_type_id)
    master_rate_mapping = RoomTypeMasterRateMapping.find_by_pool_id_and_room_type_id(pool.id, master_room_type.id)
    channel_mapping = RoomTypeMasterRateChannelMapping.find_by_room_type_master_rate_mapping_id_and_channel_id_and_room_type_id(master_rate_mapping.id, self.channel.id, room_type.id)
    rtcm = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(channel_mapping.room_type.id, channel.id)

    if rtcm.gta_travel_rate_type == GtaTravelChannel::RATE_MARGIN
      handle_margin_rate(channel_mapping, rtcm, change_set.logs, change_set_channel, property)
    elsif rtcm.gta_travel_rate_type == GtaTravelChannel::RATE_STATIC
      handle_static_rate(channel_mapping, rtcm, change_set.logs, change_set_channel, property)
    end

  end

  def create_job(change_set)
   cs = MasterRateNewRoomChangeSetChannel.create(:change_set_id => change_set.id, :channel_id => self.channel.id)
   cs.run
  end

  def channel
    GtaTravelChannel.first
  end

  def date_to_key(date)
    date.strftime('%F')
  end

  def handle_margin_rate(mrm, rtcm, logs, change_set_channel, property)
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.GTA_MarginRatesUpdateRQ('xmlns' => GtaTravelChannel::XMLNS, 'xmlns:xsi' => Constant::XMLNS_XSI_2001) {
        GtaTravelChannel.construct_user_element(xml)
        xml.RatePlan(:Id => rtcm.gta_travel_rate_plan_id) {
          xml.MarginRates(:FullPeriod => rtcm.gta_travel_full_period) {
            logs.each do |log|
              master_rate = log.master_rate
              date = master_rate.date

              if rtcm.gta_travel_support_single_rate_multiplier? and !rtcm.gta_travel_single_rate_multiplier.blank?
                xml.RoomRate(:RoomId => rtcm.gta_travel_room_type_id, :Start => date_to_key(date), :End => date_to_key(date), :Margin => rtcm.gta_travel_rate_margin, :Gross => (channel.calculate_gross(mrm.apply_value(log.amount), rtcm.gta_travel_rate_margin) * rtcm.gta_travel_single_rate_multiplier * channel.rate_multiplier(property) * channel.currency_converter(property)), :Occupancy => 1)
              end

              if rtcm.gta_travel_support_double_rate_multiplier? and !rtcm.gta_travel_double_rate_multiplier.blank?
                xml.RoomRate(:RoomId => rtcm.gta_travel_room_type_id, :Start => date_to_key(date), :End => date_to_key(date), :Margin => rtcm.gta_travel_rate_margin, :Gross => (channel.calculate_gross(mrm.apply_value(log.amount), rtcm.gta_travel_rate_margin) * rtcm.gta_travel_double_rate_multiplier * channel.rate_multiplier(property) * channel.currency_converter(property)), :Occupancy => 2)
              end

              if rtcm.gta_travel_support_triple_rate_multiplier? and !rtcm.gta_travel_triple_rate_multiplier.blank?
                xml.RoomRate(:RoomId => rtcm.gta_travel_room_type_id, :Start => date_to_key(date), :End => date_to_key(date), :Margin => rtcm.gta_travel_rate_margin, :Gross => (channel.calculate_gross(mrm.apply_value(log.amount), rtcm.gta_travel_rate_margin) * rtcm.gta_travel_triple_rate_multiplier * channel.rate_multiplier(property) * channel.currency_converter(property)), :Occupancy => 3)
              end

              if rtcm.gta_travel_support_quadruple_rate_multiplier? and !rtcm.gta_travel_quadruple_rate_multiplier.blank?
                xml.RoomRate(:RoomId => rtcm.gta_travel_room_type_id, :Start => date_to_key(date), :End => date_to_key(date), :Margin => rtcm.gta_travel_rate_margin, :Gross => (channel.calculate_gross(mrm.apply_value(log.amount), rtcm.gta_travel_rate_margin) * rtcm.gta_travel_quadruple_rate_multiplier * channel.rate_multiplier(property) * channel.currency_converter(property)), :Occupancy => 4)
              end
            end
          }
        }
      }
    end

    request_xml = builder.to_xml
    GtaTravelChannel.put_xml_change_set_channel(request_xml, change_set_channel, GtaTravelChannel::MARGIN_RATE_CREATE)

  end

  def handle_static_rate(mrm, rtcm, logs, change_set_channel, property)
    logs.each do |log|

      master_rate = log.master_rate
      date = master_rate.date

      if rtcm.gta_travel_support_single_rate_multiplier? and !rtcm.gta_travel_single_rate_multiplier.blank?
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.GTA_StaticRatesCreateRQ('xmlns' => GtaTravelChannel::XMLNS, 'xmlns:xsi' => Constant::XMLNS_XSI_2001, 'xsi:schemaLocation' => GtaTravelChannel::XMLNS_RATE_CREATE) {
            GtaTravelChannel.construct_user_element(xml)
            xml.RatePlan(:Id => rtcm.gta_travel_rate_plan_id) {
              xml.StaticRate(:Start => date_to_key(date), :End => date_to_key(date), :FullPeriod => rtcm.gta_travel_full_period, :MinPax => 1) {
                xml.StaticRoomRate(:RoomId => rtcm.gta_travel_room_type_id, :Nett => (mrm.apply_value(log.amount) * rtcm.gta_travel_single_rate_multiplier * channel.rate_multiplier(property) * channel.currency_converter(property)), :Occupancy => 1)
              }
            }
          }
        end

        request_xml = builder.to_xml
        GtaTravelChannel.post_xml_change_set_channel(request_xml, change_set_channel, GtaTravelChannel::STATIC_RATE_CREATE)

      end

      if rtcm.gta_travel_support_double_rate_multiplier? and !rtcm.gta_travel_double_rate_multiplier.blank?
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.GTA_StaticRatesCreateRQ('xmlns' => GtaTravelChannel::XMLNS, 'xmlns:xsi' => Constant::XMLNS_XSI_2001, 'xsi:schemaLocation' => GtaTravelChannel::XMLNS_RATE_CREATE) {
            GtaTravelChannel.construct_user_element(xml)
            xml.RatePlan(:Id => rtcm.gta_travel_rate_plan_id) {
              xml.StaticRate(:Start => date_to_key(date), :End => date_to_key(date), :FullPeriod => rtcm.gta_travel_full_period, :MinPax => 1) {
                xml.StaticRoomRate(:RoomId => rtcm.gta_travel_room_type_id, :Nett => (mrm.apply_value(log.amount) * rtcm.gta_travel_double_rate_multiplier * channel.rate_multiplier(property) * channel.currency_converter(property)), :Occupancy => 2)
              }
            }
          }
        end

        request_xml = builder.to_xml
        GtaTravelChannel.post_xml_change_set_channel(request_xml, change_set_channel, GtaTravelChannel::STATIC_RATE_CREATE)
      end

      if rtcm.gta_travel_support_triple_rate_multiplier? and !rtcm.gta_travel_triple_rate_multiplier.blank?
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.GTA_StaticRatesCreateRQ('xmlns' => GtaTravelChannel::XMLNS, 'xmlns:xsi' => Constant::XMLNS_XSI_2001, 'xsi:schemaLocation' => GtaTravelChannel::XMLNS_RATE_CREATE) {
            GtaTravelChannel.construct_user_element(xml)
            xml.RatePlan(:Id => rtcm.gta_travel_rate_plan_id) {
              xml.StaticRate(:Start => date_to_key(date), :End => date_to_key(date), :FullPeriod => rtcm.gta_travel_full_period, :MinPax => 1) {
                xml.StaticRoomRate(:RoomId => rtcm.gta_travel_room_type_id, :Nett => (mrm.apply_value(log.amount) * rtcm.gta_travel_triple_rate_multiplier * channel.rate_multiplier(property) * channel.currency_converter(property)), :Occupancy => 3)
              }
            }
          }
        end

        request_xml = builder.to_xml
        GtaTravelChannel.post_xml_change_set_channel(request_xml, change_set_channel, GtaTravelChannel::STATIC_RATE_CREATE)
      end

      if rtcm.gta_travel_support_quadruple_rate_multiplier? and !rtcm.gta_travel_quadruple_rate_multiplier.blank?
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.GTA_StaticRatesCreateRQ('xmlns' => GtaTravelChannel::XMLNS, 'xmlns:xsi' => Constant::XMLNS_XSI_2001, 'xsi:schemaLocation' => GtaTravelChannel::XMLNS_RATE_CREATE) {
            GtaTravelChannel.construct_user_element(xml)
            xml.RatePlan(:Id => rtcm.gta_travel_rate_plan_id) {
              xml.StaticRate(:Start => date_to_key(date), :End => date_to_key(date), :FullPeriod => rtcm.gta_travel_full_period, :MinPax => 1) {
                xml.StaticRoomRate(:RoomId => rtcm.gta_travel_room_type_id, :Nett => (mrm.apply_value(log.amount) * rtcm.gta_travel_quadruple_rate_multiplier * channel.rate_multiplier(property) * channel.currency_converter(property)), :Occupancy => 4)
              }
            }
          }
        end

        request_xml = builder.to_xml
        GtaTravelChannel.post_xml_change_set_channel(request_xml, change_set_channel, GtaTravelChannel::STATIC_RATE_CREATE)
      end
    end

  end

end
