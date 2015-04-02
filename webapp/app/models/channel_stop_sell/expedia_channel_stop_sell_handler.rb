require 'net/https'

# class to handle Expedia XML push for Stop Sell
class ExpediaChannelStopSellHandler < ChannelStopSellHandler

  def run(change_set_channel)
    change_set = change_set_channel.change_set

    # get the property of this change set
    property = change_set.logs.first.channel_stop_sell.property
    pool = change_set.pool

    # property room type that has mapping to this channel
    room_type_ids = Array.new
    property.room_types.each do |rt|
      room_type_ids << rt.id if rt.has_active_mapping_to_channel?(channel)
    end

    return if room_type_ids.blank?

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.AvailRateUpdateRQ('xmlns' => ExpediaChannel::XMLNS_AR) {
      xml.Authentication(:username => property.expedia_username, :password => property.expedia_password)
      xml.Hotel(:id => property.expedia_hotel_id)
        change_set.logs.each do |log|
          channel_stop_sell = log.channel_stop_sell
          room_type = channel_stop_sell.room_type

          # make sure room type is allowed (has mapping)
          if room_type_ids.include?(room_type.id)
            xml.AvailRateUpdate {
              xml.DateRange(:from => date_to_key(channel_stop_sell.date), :to => date_to_key(channel_stop_sell.date))
              xml.RoomType(:id => RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(room_type.id, channel.id).expedia_room_type_id, :closed => log.stop_sell)
            }
          end
        end
      }
    end

    request_xml = builder.to_xml
    ExpediaChannel.post_xml_change_set_channel(request_xml, change_set_channel, ExpediaChannel::AR)
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
    ExpediaChannel.first
  end

  def date_to_key(date)
    date.strftime('%F')
  end

end
