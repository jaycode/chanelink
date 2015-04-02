require 'net/https'

# class to handle GTA Travel XML push for Stop Sell
class GtaTravelChannelStopSellHandler < ChannelStopSellHandler

  def run(change_set_channel)
    change_set = change_set_channel.change_set

    # get the property of this change set
    property = change_set.logs.first.channel_stop_sell.property
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
            change_set.logs.each do |log|
              channel_stop_sell = log.channel_stop_sell
              room_type = channel_stop_sell.room_type
              channel_room_type_map = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(room_type.id, channel.id)

              if !channel_room_type_map.blank? and room_type_ids.include?(room_type.id)
                xml.StayDate(:Date => date_to_key(channel_stop_sell.date)) {
                  xml.Inventory(:RoomId => channel_room_type_map.gta_travel_room_type_id) {
                    xml.Restriction(:FlexibleStopSell => log.stop_sell, :InventoryType => GtaTravelChannel::INVENTORY_FLEXIBLE_TYPE)
                  }
                }
              end

            end
          }
        }
      }
    end

    request_xml = builder.to_xml
    GtaTravelChannel.put_xml_change_set_channel(request_xml, change_set_channel, GtaTravelChannel::INVENTORY_UPDATE)
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
       cs = ChannelStopSellChangeSetChannel.create(:change_set_id => change_set.id, :channel_id => self.channel.id)
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

end
