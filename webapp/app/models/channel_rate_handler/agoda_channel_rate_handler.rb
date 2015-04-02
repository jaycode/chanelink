require 'net/https'

# class to handle Agoda XML push for Rates
class AgodaChannelRateHandler < ChannelRateHandler

  def run(change_set_channel)
    change_set = change_set_channel.change_set

    # get the property of this change set
    property = change_set.logs.first.channel_rate.property
    property_channel = property.channels.find_by_channel_id(channel.id)
    pool = change_set.pool

    # property room type that has mapping to this channel
    room_type_ids = Array.new
    property.room_types.each do |rt|
      room_type_ids << rt.id if rt.has_active_mapping_to_channel?(channel) and !rt.has_master_rate_mapping_to_channel?(channel, pool)
    end

    puts room_type_ids

    return if room_type_ids.blank?

    rate_pushed = false

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.SetHotelInventoryRequest('xmlns' => AgodaChannel::XMLNS) {
        xml.Authentication(:APIKey => AgodaChannel::API_KEY, :HotelID => property.agoda_hotel_id)
        xml.HotelInventoryList {
          change_set.logs.each do |log|
            channel_rate = log.channel_rate
            room_type = channel_rate.room_type
            channel_mapping = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(room_type.id, channel.id)
            
            # make sure room type is allowed (has mapping)
            if room_type_ids.include?(room_type.id)

              # skip if inventory 0 or does not exist
              inv = Inventory.find_by_date_and_property_id_and_pool_id_and_room_type_id(channel_rate.date, property.id, pool.id, room_type.id)
              next if inv.blank? or inv.total_rooms == 0

              rate_pushed = true

              xml.HotelInventory {
                xml.RoomType(:RoomTypeID => channel_mapping.agoda_room_type_id, :RatePlanID => AgodaChannel::DEFAULT_RATE_PLAN_ID)
                xml.DateRange(:Type => "Stay", :Start => date_to_key(channel_rate.date), :End => date_to_key(channel_rate.date))
                xml.InventoryRate(:Currency => AgodaChannel.get_currency(property_channel)) {
                  xml.SingleRate AgodaChannel.calculate_single_rate(channel_mapping, log.amount) * channel.rate_multiplier(property) * channel.currency_converter(property)
                  xml.DoubleRate AgodaChannel.calculate_double_rate(channel_mapping, log.amount) * channel.rate_multiplier(property) * channel.currency_converter(property) unless channel_mapping.agoda_double_rate_multiplier.blank?
                  xml.FullRate AgodaChannel.calculate_full_rate(channel_mapping, log.amount) * channel.rate_multiplier(property) * channel.currency_converter(property) unless channel_mapping.agoda_full_rate_multiplier.blank?
                  xml.ExtraBed AgodaChannel.get_extra_bed(channel_mapping) unless channel_mapping.agoda_extra_bed_rate.blank?
                }
              }
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
     channel_mapping = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(rt_id, self.channel.id)
     master_rate_mapping = RoomTypeMasterRateChannelMapping.pool_id(pool.id).find_by_room_type_id_and_channel_id(rt_id, self.channel.id)
     # if room type relate the channel then run the xml push
     if !channel_mapping.blank? and master_rate_mapping.blank?
       cs = ChannelRateChangeSetChannel.create(:change_set_id => change_set.id, :channel_id => self.channel.id)
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
