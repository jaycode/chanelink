require 'net/https'

# class to handle Gta Travel XML push for Min stay
class GtaTravelChannelMinStayHandler < ChannelMinStayHandler

  def run(change_set_channel)
    change_set = change_set_channel.change_set

    # get the property of this change set
    property = change_set.logs.first.channel_min_stay.property
    property_channel = property.channels.find_by_channel_id(channel.id)
    pool = change_set.pool

    # property room type that has mapping to this channel
    room_type_ids = Array.new
    property.room_types.each do |rt|
      room_type_ids << rt.id if rt.has_active_mapping_to_channel?(channel) and !rt.has_master_rate_mapping_to_channel?(channel, pool)
    end

    return if room_type_ids.blank?

    logs_by_room_type = change_set.logs_organized_by_room_type_id

    logs_by_room_type.keys.each do |rt_id|
      next unless room_type_ids.include?(rt_id)

      room_type = property.room_types.find(rt_id)
      channel_room_type_map = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(room_type.id, channel.id)
      room_type_logs = logs_by_room_type[rt_id]

      if channel_room_type_map.gta_travel_rate_type == GtaTravelChannel::RATE_MARGIN
        handle_margin_rate(channel_room_type_map, room_type_logs, change_set_channel, property_channel)
      elsif channel_room_type_map.gta_travel_rate_type == GtaTravelChannel::RATE_STATIC
        handle_static_rate(channel_room_type_map, room_type_logs, change_set_channel, property_channel)
      end
    end
  end

  # determine whether the change set relate to this channel
  def create_job(change_set)
   # all room types id in this change set
   room_type_ids = change_set.room_type_ids
   pool = change_set.pool

   room_type_ids.each do |rt_id|
     channel_mapping = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(rt_id, self.channel.id)
     # if room type relate the channel then run the xml push
     if !channel_mapping.blank?
       cs = ChannelMinStayChangeSetChannel.create(:change_set_id => change_set.id, :channel_id => self.channel.id)
       cs.delay.run
       return
     end
   end

  end

  def channel
    GtaTravelChannel.first
  end

  def date_to_key(date)
    date.strftime('%F')
  end

  private

  def handle_static_rate(rtcm, logs, change_set_channel, property_channel)
    property = property_channel.property
    logs.each do |log|
      min_stay = log.channel_min_stay
      date = min_stay.date
      rate_found = get_rate(rtcm, min_stay.date, property_channel)

      if rtcm.gta_travel_support_single_rate_multiplier? and !rtcm.gta_travel_single_rate_multiplier.blank?
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.GTA_StaticRatesCreateRQ('xmlns' => GtaTravelChannel::XMLNS, 'xmlns:xsi' => Constant::XMLNS_XSI_2001, 'xsi:schemaLocation' => GtaTravelChannel::XMLNS_RATE_CREATE) {
            GtaTravelChannel.construct_user_element(xml)
            xml.RatePlan(:Id => rtcm.gta_travel_rate_plan_id) {
              xml.StaticRate(:Start => date_to_key(date), :End => date_to_key(date), :MinNights => min_stay.min_stay, :MinPax => 1, :FullPeriod => rtcm.gta_travel_full_period) {
                xml.StaticRoomRate(:RoomId => rtcm.gta_travel_room_type_id, :Nett => (rate_found * rtcm.gta_travel_single_rate_multiplier * channel.rate_multiplier(property) * channel.currency_converter(property)), :Occupancy => 1)
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
              xml.StaticRate(:Start => date_to_key(date), :End => date_to_key(date), :MinNights => min_stay.min_stay, :MinPax => 1, :FullPeriod => rtcm.gta_travel_full_period) {
                xml.StaticRoomRate(:RoomId => rtcm.gta_travel_room_type_id, :Nett => (rate_found * rtcm.gta_travel_double_rate_multiplier * channel.rate_multiplier(property) * channel.currency_converter(property)), :Occupancy => 2)
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
              xml.StaticRate(:Start => date_to_key(date), :End => date_to_key(date), :MinNights => min_stay.min_stay, :MinPax => 1, :FullPeriod => rtcm.gta_travel_full_period) {
                xml.StaticRoomRate(:RoomId => rtcm.gta_travel_room_type_id, :Nett => (rate_found * rtcm.gta_travel_triple_rate_multiplier * channel.rate_multiplier(property) * channel.currency_converter(property)), :Occupancy => 3)
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
              xml.StaticRate(:Start => date_to_key(date), :End => date_to_key(date), :MinNights => min_stay.min_stay, :MinPax => 1, :FullPeriod => rtcm.gta_travel_full_period) {
                xml.StaticRoomRate(:RoomId => rtcm.gta_travel_room_type_id, :Nett => (rate_found * rtcm.gta_travel_quadruple_rate_multiplier * channel.rate_multiplier(property) * channel.currency_converter(property)), :Occupancy => 4)
              }
            }
          }
        end

        request_xml = builder.to_xml
        GtaTravelChannel.post_xml_change_set_channel(request_xml, change_set_channel, GtaTravelChannel::STATIC_RATE_CREATE)
      end
    end
    
  end

  def handle_margin_rate(rtcm, logs, change_set_channel, property_channel)
    property = property_channel.property
    logs.each do |log|
      min_stay = log.channel_min_stay
      date = min_stay.date
      rate_found = get_rate(rtcm, min_stay.date, property_channel)

      builder = Nokogiri::XML::Builder.new do |xml|
        xml.GTA_MarginRatesUpdateRQ('xmlns' => GtaTravelChannel::XMLNS, 'xmlns:xsi' => Constant::XMLNS_XSI_2001) {
          GtaTravelChannel.construct_user_element(xml)
          xml.RatePlan(:Id => rtcm.gta_travel_rate_plan_id) {
            xml.MarginRates(:FullPeriod => rtcm.gta_travel_full_period, :MinNights => min_stay.min_stay) {
              
              if rtcm.gta_travel_support_single_rate_multiplier? and !rtcm.gta_travel_single_rate_multiplier.blank?
                xml.RoomRate(:RoomId => rtcm.gta_travel_room_type_id, :Start => date_to_key(date), :End => date_to_key(date), :Margin => rtcm.gta_travel_rate_margin, :Gross => (channel.calculate_gross(rate_found, rtcm.gta_travel_rate_margin) * rtcm.gta_travel_single_rate_multiplier * channel.rate_multiplier(property) * channel.currency_converter(property)), :Occupancy => 1)
              end

              if rtcm.gta_travel_support_double_rate_multiplier? and !rtcm.gta_travel_double_rate_multiplier.blank?
                xml.RoomRate(:RoomId => rtcm.gta_travel_room_type_id, :Start => date_to_key(date), :End => date_to_key(date), :Margin => rtcm.gta_travel_rate_margin, :Gross => (channel.calculate_gross(rate_found, rtcm.gta_travel_rate_margin) * rtcm.gta_travel_double_rate_multiplier * channel.rate_multiplier(property) * channel.currency_converter(property)), :Occupancy => 2)
              end

              if rtcm.gta_travel_support_triple_rate_multiplier? and !rtcm.gta_travel_triple_rate_multiplier.blank?
                xml.RoomRate(:RoomId => rtcm.gta_travel_room_type_id, :Start => date_to_key(date), :End => date_to_key(date), :Margin => rtcm.gta_travel_rate_margin, :Gross => (channel.calculate_gross(rate_found, rtcm.gta_travel_rate_margin) * rtcm.gta_travel_triple_rate_multiplier * channel.rate_multiplier(property) * channel.currency_converter(property)), :Occupancy => 3)
              end

              if rtcm.gta_travel_support_quadruple_rate_multiplier? and !rtcm.gta_travel_quadruple_rate_multiplier.blank?
                xml.RoomRate(:RoomId => rtcm.gta_travel_room_type_id, :Start => date_to_key(date), :End => date_to_key(date), :Margin => rtcm.gta_travel_rate_margin, :Gross => (channel.calculate_gross(rate_found, rtcm.gta_travel_rate_margin) * rtcm.gta_travel_quadruple_rate_multiplier * channel.rate_multiplier(property) * channel.currency_converter(property)), :Occupancy => 4)
              end
            }
          }
        }
      end

      request_xml = builder.to_xml
      GtaTravelChannel.put_xml_change_set_channel(request_xml, change_set_channel, GtaTravelChannel::MARGIN_RATE_CREATE)
    end
  end

  # decide which rate to be pushed
  def get_rate(rtcm, date, property_channel)
    result = 0.0
    master_rate_channel_mapping = RoomTypeMasterRateChannelMapping.pool_id(property_channel.pool_id).find_by_room_type_id_and_channel_id(rtcm.room_type_id, channel.id)

    # if master rate mapping exist then get master rate
    if !master_rate_channel_mapping.blank?
      master_rate_map = master_rate_channel_mapping.master_rate_mapping

      master_rate = MasterRate.find_by_date_and_property_id_and_pool_id_and_room_type_id(date, master_rate_map.room_type.property.id, master_rate_map.pool_id, master_rate_map.room_type_id)
      result = master_rate_channel_mapping.apply_value(master_rate.amount) if !master_rate.blank?
      puts "master rate #{master_rate.amount}" if !master_rate.blank?
    # if not using master rate
    else
      channel_rate = ChannelRate.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(date, property_channel.property_id, property_channel.pool_id, rtcm.room_type_id, channel.id)
      result = channel_rate.amount if !channel_rate.blank?
      puts "channel rate #{channel_rate.amount}" if !channel_rate.blank?
    end
    puts "result #{result}"
    result
  end

end
