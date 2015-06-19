require 'net/https'

# class to handle gta travel push XML for inventory change
class GtaTravelInventoryHandler < InventoryHandler

  def run(change_set_channel)
    change_set = change_set_channel.change_set

    # need to control amount of inventory going to gta, divide by 31 days range each
    logs = change_set.logs

    start_period = DateTime.now.in_time_zone(Time.zone).beginning_of_day
    end_period = (DateTime.now + 400.days).end_of_day

    loop_date = start_period
    index = 1

    while loop_date <= end_period
      logs_fragment = slice_logs_by_date(logs, loop_date, (loop_date + 31.days).end_of_day)
      run_by_logs(logs_fragment, change_set_channel, index) unless logs_fragment.blank?
      index = index + 1
      loop_date = (loop_date + 31.days).end_of_day
    end
  end

  def run_by_logs(logs_to_use, change_set_channel, fragment_id = nil)
    change_set = change_set_channel.change_set

    # get the property of this change set
    property = change_set.logs.first.inventory.property
    property_channel = property.channels.find_by_channel_id(channel.id)

    # property room type that has mapping to this channel
    room_type_ids = Array.new
    property.room_types.each do |rt|
      room_type_ids << rt.id if rt.has_active_mapping_to_channel?(channel)
    end

    return if room_type_ids.blank?

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.GTA_InventoryUpdateRQ('xmlns' => GtaTravelChannel::XMLNS, 'xmlns:xsi' => Constant::XMLNS_XSI_2001, 'xsi:schemaLocation' => GtaTravelChannel::XMLNS_INVENTORY_UPDATE) {
        GtaTravelChannel.construct_user_element(xml)
        xml.InventoryBlock(:ContractId => property_channel.gta_travel_contract_id, :PropertyId => property_channel.gta_travel_property_id) {
          xml.RoomStyle{
            puts "logs to use #{logs_to_use.size}"
            logs_to_use.each do |log|
              inv = log.inventory
              room_type = inv.room_type
              channel_room_type_map = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(room_type.id, channel.id)

              if !channel_room_type_map.blank? and room_type_ids.include?(room_type.id)
                create_hotel_inventory_xml(xml, channel_room_type_map.gta_travel_room_type_id, inv.date, log.total_rooms, channel_room_type_map, property_channel)
              end

              # now send to linked room type
              if room_type.is_inventory_feeder?
                room_type.consumer_room_types.each do |consumer_room_type|
                  channel_room_type_map = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(consumer_room_type.id, channel.id)

                  if !channel_room_type_map.blank?
                    create_hotel_inventory_xml(xml, channel_room_type_map.gta_travel_room_type_id, inv.date, log.total_rooms, channel_room_type_map, property_channel)
                  end
                end
              end
            end
          }
        }
      }
    end

    request_xml = builder.to_xml
    GtaTravelChannel.put_xml_change_set_channel(request_xml, change_set_channel, GtaTravelChannel::INVENTORY_UPDATE, fragment_id)
  end

  def channel
    GtaTravelChannel.first
  end

  def date_to_key(date)
    date.strftime('%F')
  end

  private

  # helper to build XML push
  def create_hotel_inventory_xml(xml, channel_room_type_id, date, rooms, rtcm, property_channel)
    xml.StayDate(:Date => date_to_key(date)) {
      xml.Inventory(:RoomId => channel_room_type_id) {
        xml.Detail(:FreeSale => GtaTravelChannel::FREESALE_FALSE, :InventoryType => GtaTravelChannel::INVENTORY_FLEXIBLE_TYPE, :Quantity => rooms)
      }
    }
  end

  def slice_logs_by_date(logs, date_from, date_to)
    result = Array.new
    logs.each do |log|
      date = log.inventory.date
      result << log if date >= date_from and date <= date_to
    end
    result
  end

end
