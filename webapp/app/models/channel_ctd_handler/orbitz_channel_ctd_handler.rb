require 'net/https'

# class to handle Orbitz push for CTD
class OrbitzChannelCtdHandler < ChannelCtdHandler

  def run(change_set_channel)
    change_set = change_set_channel.change_set

    # need to control amount of data going to expedia, divide by 150 rows each
    logs = change_set.logs

    if logs.size > OrbitzChannel::SIZING
      logs_to_slice = Array.new(logs)
      index = 1
      while !logs_to_slice.blank?
        logs_fragment = logs_to_slice.slice!(0, OrbitzChannel::SIZING)
        run_by_logs(logs_fragment, change_set_channel, index)

        index = index + 1
      end
    else
      run_by_logs(logs, change_set_channel)
    end

  end

  def run_by_logs(logs_to_use, change_set_channel, fragment_id = nil)
    change_set = change_set_channel.change_set

    # get the property of this change set
    property = change_set.logs.first.channel_ctd.property
    property_channel = property.channels.find_by_channel_id(channel.id)

    # property room type that has mapping to this channel
    room_type_ids = Array.new
    property.room_types.each do |rt|
      room_type_ids << rt.id if rt.has_active_mapping_to_channel?(channel)
    end

    return if room_type_ids.blank?

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.OTA_HotelAvailNotifRQ(:xmlns => OrbitzChannel::XMLNS) {
        OrbitzChannel.construct_auth_element(xml)
        xml.AvailStatusMessages(:ChainCode => property_channel.orbitz_chain_code, :HotelCode => property_channel.orbitz_hotel_code) {
          logs_to_use.each do |log|
            channel_ctd = log.channel_ctd
            room_type = channel_ctd.room_type
            channel_room_type_map = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(room_type.id, channel.id)

            xml.AvailStatusMessage {
              xml.StatusApplicationControl(:Start => date_to_key(channel_ctd.date), :End => date_to_key(channel_ctd.date), :InvCode => channel_room_type_map.orbitz_room_type_id, :InvCodeApplication => "InvCode", :RatePlanCode => channel_room_type_map.orbitz_rate_plan_id)
              xml.RestrictionStatus(:Restriction => "Departure", :Status => (channel_ctd.ctd? ? "Open" : "Closed"))
            }
          end
        }
      }
    end

    request_xml = builder.to_xml
    OrbitzChannel.post_xml_change_set_channel(request_xml, change_set_channel, OrbitzChannel::OTHER)
  end

  # determine whether the change set relate to this channel
  def create_job(change_set)
   # all room types id in this change set
   room_type_ids = change_set.room_type_ids
   pool = change_set.pool

   # if room type relate the channel then run the xml push
   room_type_ids.each do |rt_id|
     channel_mapping = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(rt_id, self.channel.id)

     if !channel_mapping.blank?
       cs = ChannelCtdChangeSetChannel.create(:change_set_id => change_set.id, :channel_id => self.channel.id)
       cs.delay.run
       return
     end
   end
   
  end

  def channel
    OrbitzChannel.first
  end

  def date_to_key(date)
    date.strftime('%F')
  end

end
