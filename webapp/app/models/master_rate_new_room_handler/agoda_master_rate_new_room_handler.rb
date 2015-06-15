require 'net/https'

# handler to push XML to Agoda because of new room type mapping created using master rate
class AgodaMasterRateNewRoomHandler < MasterRateHandler

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

    rate_pushed = false

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.SetHotelInventoryRequest('xmlns' => AgodaChannel::XMLNS) {
        xml.Authentication(:APIKey => AgodaChannel::API_KEY, :HotelID => property.agoda_hotel_id)
        xml.HotelInventoryList {
          change_set.logs.each do |log|
            master_rate = log.master_rate

            # skip if inventory 0 or does not exist
            inv = nil
            if room_type.is_inventory_linked?
              linked = room_type.linked_room_type
              inv = Inventory.find_by_date_and_property_id_and_pool_id_and_room_type_id(master_rate.date, property.id, pool.id, linked.id)
            else
              inv = Inventory.find_by_date_and_property_id_and_pool_id_and_room_type_id(master_rate.date, property.id, pool.id, channel_mapping.room_type.id)
            end
            
            next if inv.blank? or inv.total_rooms == 0

            rate_pushed = true
            
            xml.HotelInventory {
              xml.RoomType(:RoomTypeID => room_type_channel_mapping.ota_room_type_id, :RatePlanID => AgodaChannel::DEFAULT_RATE_PLAN_ID)
              xml.DateRange(:Type => "Stay", :Start => date_to_key(master_rate.date), :End => date_to_key(master_rate.date))
              xml.InventoryRate(:Currency => AgodaChannel.get_currency(property_channel)) {
                puts "#{log.amount} #{AgodaChannel.calculate_single_rate(room_type_channel_mapping, channel_mapping.apply_value(log.amount))} #{channel.rate_multiplier(property)}"
                xml.SingleRate AgodaChannel.calculate_single_rate(room_type_channel_mapping, channel_mapping.apply_value(log.amount)) * channel.rate_multiplier(property) * channel.currency_converter(property)
                xml.DoubleRate AgodaChannel.calculate_double_rate(room_type_channel_mapping, channel_mapping.apply_value(log.amount)) * channel.rate_multiplier(property) * channel.currency_converter(property) unless room_type_channel_mapping.agoda_double_rate_multiplier.blank?
                xml.FullRate AgodaChannel.calculate_full_rate(room_type_channel_mapping, channel_mapping.apply_value(log.amount)) * channel.rate_multiplier(property) * channel.currency_converter(property) unless room_type_channel_mapping.agoda_full_rate_multiplier.blank?
                xml.ExtraBed AgodaChannel.get_extra_bed(room_type_channel_mapping) unless room_type_channel_mapping.agoda_extra_bed_rate.blank?
              }
            }
          end
        }
      }
    end

    if rate_pushed
      request_xml = builder.to_xml
      AgodaChannel.post_xml_change_set_channel(request_xml, change_set_channel)
    end
  end

  def create_job(change_set)
   cs = MasterRateNewRoomChangeSetChannel.create(:change_set_id => change_set.id, :channel_id => self.channel.id)
   cs.delay.run
  end

  def channel
    AgodaChannel.first
  end

  def date_to_key(date)
    date.strftime('%F')
  end

end
