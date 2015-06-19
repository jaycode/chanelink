require 'net/https'

# class to handle agoda push XML for inventory change
class AgodaInventoryHandler < InventoryHandler

  def run(change_set_channel)
    change_set = change_set_channel.change_set

    logs = change_set.logs
    if logs.blank?
      # This means change_set is invalid, delete it.
      change_set.destroy
    else
      # get the property of this change set
      property = logs.first.inventory.property
      property_channel = property.channels.find_by_channel_id(channel.id)

      # property room type that has mapping to this channel
      room_type_ids = Array.new
      property.room_types.each do |rt|
        room_type_ids << rt.id if rt.has_active_mapping_to_channel?(channel)
      end

      return if room_type_ids.blank?

      builder = Nokogiri::XML::Builder.new do |xml|
        xml.SetHotelInventoryRequest('xmlns' => AgodaChannel::XMLNS) {
          xml.Authentication(:APIKey => AgodaChannel::API_KEY, :HotelID => property.agoda_hotel_id)
          xml.HotelInventoryList {
            change_set.logs.each do |log|
              inv = log.inventory
              room_type = inv.room_type
              channel_room_type_map = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(room_type.id, channel.id)

              if !channel_room_type_map.blank? and room_type_ids.include?(room_type.id)
                create_hotel_inventory_xml(xml, channel_room_type_map.ota_room_type_id, inv.date, log.total_rooms, channel_room_type_map, property_channel)
              end

              # now send to linked room type
              if room_type.is_inventory_feeder?
                room_type.consumer_room_types.each do |consumer_room_type|
                  channel_room_type_map = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(consumer_room_type.id, channel.id)

                  if !channel_room_type_map.blank?
                    create_hotel_inventory_xml(xml, channel_room_type_map.ota_room_type_id, inv.date, log.total_rooms, channel_room_type_map, property_channel)
                  end
                end
              end
            end
          }
        }
      end

      request_xml = builder.to_xml
      AgodaChannel.post_xml_change_set_channel(request_xml, change_set_channel)
    end
  end

  def channel
    AgodaChannel.first
  end

  def date_to_key(date)
    date.strftime('%F')
  end

  def get_inventories(property, room_type, date_start, date_end, rate_type)
    inventories = Array.new
    get_inventories_xml(property, room_type, date_start, date_end, rate_type) do |xml_doc|
      # Each inventory_xml is allotments available at given date that looks as follows:
      #       <HotelInventory>
      #         <RoomType RoomTypeID="461004" RatePlanID="1" />
      #         <DateRange Type="Stay" Start="2012-11-22" End="2012-11-22" />
      #         <InventoryRate Currency="USD">
      #           <SingleRate>100.00</SingleRate><DoubleRate>100.00</DoubleRate><FullRate>0.00</FullRate>
      #           <ExtraPerson>50.00</ExtraPerson>
      #           <ExtraAdult>50.00</ExtraAdult>
      #           <ExtraChild>0.00</ExtraChild>
      #           <ExtraBed>10.00</ExtraBed>
      #         </InventoryRate>
      #         <InventoryAllotment>
      #           <RegularAllotment>10</RegularAllotment>
      #           <RegularAllotmentUsed>0</RegularAllotmentUsed>
      #           <GuaranteedAllotment>0</GuaranteedAllotment>
      #           <GuaranteedAllotmentUsed>0</GuaranteedAllotmentUsed>
      #           <CutOffDayNormal>0</CutOffDayNormal>
      #           <CutOffDayGuaranteed>0</CutOffDayGuaranteed>
      #           <CloseOutRegularAllotment>False</CloseOutRegularAllotment>
      #           <ClosedToArrival>False</ClosedToArrival>
      #           <ClosedToDeparture>False</ClosedToDeparture>
      #           <BreakfastIncluded>False</BreakfastIncluded>
      #           <PromotionBlackout>False</PromotionBlackout>
      #           <MinLOS>1</MinLOS>
      #           <MaxLOS>0</MaxLOS>
      #         </InventoryAllotment>
      #       </HotelInventory>
      # From it, at least for now we only need number of rooms available at given date
      xml_doc.xpath('//HotelInventory').each do |inventory_xml|
        inventories << InventoryXml.new(
          :room_type_id => inventory_xml.xpath('RoomType').attr('RoomTypeID').value,
          :rate_type_id => inventory_xml.xpath('RoomType').attr('RatePlanID').value,
          :date => inventory_xml.xpath('DateRange').attr('Start').value,
          :total_rooms => inventory_xml.xpath('InventoryAllotment/RegularAllotment').text.to_i -
            inventory_xml.xpath('InventoryAllotment/RegularAllotmentUsed').text.to_i
        )
      end
    end
    inventories
  end

  def get_inventories_xml(property, room_type, date_start, date_end, rate_type, &block)
    channel = AgodaChannel.first

    # Need to get ota room type and rate type:
    room_type_channel_mapping = RoomTypeChannelMapping.first(
      :conditions => {
        :room_type_id => room_type.id,
        :rate_type_id => rate_type.id,
        :channel_id => channel.id
      }
    )

    # construct xml to request room type list
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.GetHotelInventoryRequest('xmlns' => AgodaChannel::XMLNS) {
        xml.Authentication(:APIKey => AgodaChannel::API_KEY, :HotelID => property.agoda_hotel_id)
        xml.RoomType(
          :RoomTypeID => room_type_channel_mapping.ota_room_type_id,
          # :RoomTypeID => '0',
          :RatePlanID => room_type_channel_mapping.ota_rate_type_id
        )
        xml.DateRange(
          :Type => 'Stay',
          :Start => date_start.to_s,
          :End => date_end.to_s
        )
        # todo: Multi-language
        xml.RequestedLanguage 'en'
      }
    end

    request_xml   = builder.to_xml
    response_xml  = AgodaChannel.post_xml(request_xml)
    response_xml  = response_xml.gsub(/xmlns=\"([^\"]*)\"/, "")

    puts '============'
    puts 'REQUEST:'
    puts YAML::dump(request_xml)
    puts '============'
    puts YAML::dump(response_xml)[0...200]
    puts '============'

    xml_doc = Nokogiri::XML(response_xml)
    begin
      success = xml_doc.xpath('//StatusResponse').attr('status').value
      # 204 is when no inventory returned.
      if success == '200' or success == '204'
        block.call xml_doc
      else
        property_channel  = PropertyChannel.find_by_property_id_and_channel_id(property.id, channel.id)
        logs_fetching_failure channel.name, request_xml, xml_doc, property, property_channel, APP_CONFIG[:agoda_endpoint]
      end
    rescue
      property_channel  = PropertyChannel.find_by_property_id_and_channel_id(property.id, channel.id)
      logs_fetching_failure channel.name, request_xml, xml_doc, property, property_channel, APP_CONFIG[:agoda_endpoint]
    end
  end

  private

  # helper to build XML push
  def create_hotel_inventory_xml(xml, channel_room_type_id, date, rooms, rtcm, property_channel)
    xml.HotelInventory {
      xml.RoomType(:RoomTypeID => channel_room_type_id, :RatePlanID => AgodaChannel::DEFAULT_RATE_PLAN_ID)
      xml.DateRange(:Type => "Stay", :Start => date_to_key(date), :End => date_to_key(date))

      rate_found = get_rate(rtcm, date, property_channel)
      puts "rate #{rate_found}"

      # agoda demands rate to be pushed with inventory
      if !rtcm.agoda_extra_bed_rate.blank? or rate_found > 0
        puts "rate #{rate_found}"
        xml.InventoryRate(:Currency => AgodaChannel.get_currency(property_channel)) {
          if rate_found > 0
            puts "rate #{rate_found}"
            xml.SingleRate AgodaChannel.calculate_single_rate(rtcm, rate_found) * channel.rate_multiplier(property_channel.property) * channel.currency_converter(property_channel.property)
            xml.DoubleRate AgodaChannel.calculate_double_rate(rtcm, rate_found) * channel.rate_multiplier(property_channel.property) * channel.currency_converter(property_channel.property) unless rtcm.agoda_double_rate_multiplier.blank?
            xml.FullRate AgodaChannel.calculate_full_rate(rtcm, rate_found) * channel.rate_multiplier(property_channel.property) * channel.currency_converter(property_channel.property) unless rtcm.agoda_full_rate_multiplier.blank?
          end

          xml.ExtraBed AgodaChannel.get_extra_bed(rtcm) if !rtcm.agoda_extra_bed_rate.blank?
        }
      end
      xml.InventoryAllotment {
        xml.RegularAllotment rooms
        xml.BreakfastIncluded rtcm.agoda_breakfast_inclusion
      }
    }
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
