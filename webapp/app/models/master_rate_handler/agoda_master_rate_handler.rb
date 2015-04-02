require 'net/https'

# handler to push XML to Agoda because of master rate changes
class AgodaMasterRateHandler < MasterRateHandler

  def run(change_set_channel)
    change_set = change_set_channel.change_set

    # get the property of this change set
    property = change_set.logs.first.master_rate.property
    property_channel = property.channels.find_by_channel_id(channel.id)
    pool = change_set.pool

    # property room type that has mapping to this channel
    # also has master rate mapping to the pool
    room_type_ids = Array.new
    property.room_types.each do |rt|
      room_type_ids << rt.id if rt.has_master_rate_mapping?(pool) and rt.has_active_mapping_to_channel?(channel)
    end

    return if room_type_ids.blank?

    rate_pushed = false

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.SetHotelInventoryRequest('xmlns' => AgodaChannel::XMLNS) {
        xml.Authentication(:APIKey => AgodaChannel::API_KEY, :HotelID => property.agoda_hotel_id)
        xml.HotelInventoryList {
          change_set.logs.each do |log|
            master_rate = log.master_rate
            room_type = master_rate.room_type

            # make sure room type is allowed (has mapping)
            if room_type_ids.include?(room_type.id)
              master_rate_mapping = RoomTypeMasterRateMapping.find_by_pool_id_and_room_type_id(pool.id, room_type.id)
              
              RoomTypeMasterRateChannelMapping.find_all_by_room_type_master_rate_mapping_id_and_channel_id(master_rate_mapping.id, self.channel.id).each do |channel_mapping|
                rtcm = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(channel_mapping.room_type.id, channel.id)

                # skip if inventory 0 or does not exist
                inv = Inventory.find_by_date_and_property_id_and_pool_id_and_room_type_id(master_rate.date, property.id, pool.id, channel_mapping.room_type.id)
                next if inv.blank? or inv.total_rooms == 0

                rate_pushed = true

                xml.HotelInventory {
                  xml.RoomType(:RoomTypeID => rtcm.agoda_room_type_id, :RatePlanID => AgodaChannel::DEFAULT_RATE_PLAN_ID)
                  xml.DateRange(:Type => "Stay", :Start => date_to_key(master_rate.date), :End => date_to_key(master_rate.date))
                  xml.InventoryRate(:Currency => AgodaChannel.get_currency(property_channel)) {
                    xml.SingleRate AgodaChannel.calculate_single_rate(rtcm, channel_mapping.apply_value(log.amount)) * channel.rate_multiplier(property) * channel.currency_converter(property)
                    xml.DoubleRate AgodaChannel.calculate_double_rate(rtcm, channel_mapping.apply_value(log.amount)) * channel.rate_multiplier(property) * channel.currency_converter(property) unless rtcm.agoda_double_rate_multiplier.blank?
                    xml.FullRate AgodaChannel.calculate_full_rate(rtcm, channel_mapping.apply_value(log.amount)) * channel.rate_multiplier(property) * channel.currency_converter(property) unless rtcm.agoda_full_rate_multiplier.blank?
                    xml.ExtraBed AgodaChannel.get_extra_bed(rtcm) unless rtcm.agoda_extra_bed_rate.blank?
                  }
                }
              end
              
            end
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
   # all room types id in this change set
   room_type_ids = change_set.room_type_ids
   pool = change_set.pool

   room_type_ids.each do |rt_id|
     # check channel mapping for room type exist
     # and check at least one master rate mapping exist
     # channel_mapping = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(rt_id, self.channel.id)
     master_rate_mapping = RoomTypeMasterRateChannelMapping.pool_id(pool.id).master_room_type_id(rt_id).find_by_channel_id(self.channel.id)

     unless master_rate_mapping.blank?
       cs = MasterRateChangeSetChannel.create(:change_set_id => change_set.id, :channel_id => self.channel.id)
       cs.delay.run
       return
     end
   end
   
  end

  def channel
    AgodaChannel.first
  end

  def date_to_key(date)
    date.strftime('%F')
  end

end
