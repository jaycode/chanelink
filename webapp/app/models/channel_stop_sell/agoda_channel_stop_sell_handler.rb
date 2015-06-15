require 'net/https'

# class to handle Agoda XML push for Stop Sell
class AgodaChannelStopSellHandler < ChannelStopSellHandler

  def run(change_set_channel)
    change_set = change_set_channel.change_set

    # get the property of this change set
    property = change_set.logs.first.channel_stop_sell.property
    pool = change_set.pool

    puts "stop sell here 0"

    # property room type that has mapping to this channel
    room_type_ids = Array.new
    property.room_types.each do |rt|
      room_type_ids << rt.id if rt.has_active_mapping_to_channel?(channel)
    end

    puts "stop sell here 1"

    return if room_type_ids.blank?

    puts "stop sell here 2"

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.SetHotelInventoryRequest('xmlns' => AgodaChannel::XMLNS) {
        xml.Authentication(:APIKey => AgodaChannel::API_KEY, :HotelID => property.agoda_hotel_id)
        xml.HotelInventoryList {
          puts "stop sell here 3"
          change_set.logs.each do |log|
            channel_stop_sell = log.channel_stop_sell
            room_type = channel_stop_sell.room_type
            puts "stop sell here 4"
            
            # make sure room type is allowed (has mapping)
            if room_type_ids.include?(room_type.id)
              xml.HotelInventory {
                xml.RoomType(:RoomTypeID => RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(room_type.id, channel.id).ota_room_type_id, :RatePlanID => AgodaChannel::DEFAULT_RATE_PLAN_ID)
                xml.DateRange(:Type => "Stay", :Start => date_to_key(channel_stop_sell.date), :End => date_to_key(channel_stop_sell.date))
                xml.InventoryAllotment {
                  xml.CloseOutRegularAllotment log.stop_sell
                }
                puts "stop sell here 5"
              }
            end
          end
        }
      }
    end

    puts "stop sell here 6"

    request_xml = builder.to_xml
    AgodaChannel.post_xml_change_set_channel(request_xml, change_set_channel)
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
    AgodaChannel.first
  end

  def date_to_key(date)
    date.strftime('%F')
  end

end
