require 'net/https'

# class to handle Ctrip XML push for Min Stay
class CtripChannelMinStayHandler < ChannelMinStayHandler

  def run(change_set_channel)
    
    change_set = change_set_channel.change_set

    # get the property of this change set
    property = change_set.logs.first.channel_min_stay.property

    # property room type that has mapping to this channel
    room_type_ids = Array.new
    property.room_types.each do |rt|
      room_type_ids << rt.id if rt.has_active_mapping_to_channel?(channel)
    end

    return if room_type_ids.blank?

    logs_by_room_type = change_set.logs_organized_by_room_type_id

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.OTA_HotelRateAmountNotifRQ(:Version => CtripChannel::API_VERSION, :PrimaryLangID => CtripChannel::PRIMARY_LANG, :TimeStamp => "2011-12-17T09:30:47Z", :xmlns => CtripChannel::XMLNS) {
        CtripChannel.construct_user_element(xml)
        xml.RateAmountMessages(:HotelCode => property_channel.ctrip_hotel_code) {
          logs_by_room_type.keys.each do |rt_id|
            next unless room_type_ids.include?(rt_id)

            room_type = property.room_types.find(rt_id)
            channel_room_type_map = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(room_type.id, channel.id)
            room_type_logs = logs_by_room_type[rt_id]

            xml.RateAmountMessage {
              xml.StatusApplicationControl(
                :RatePlanCategory => channel_room_type_map.ota_rate_type_id,
                :RatePlanCode => channel_room_type_map.ota_room_type_id)
              xml.Rates {
                room_type_logs.each do |log|
                  xml.Rate(:End => date_to_key(log.channel_rate.date), :Start => date_to_key(log.channel_rate.date), :UnitMultiplier => "2") {
                    xml.BaseByGuestAmts {
                      xml.BaseByGuestAmt(:Code => '', :AmountAfterTax => "600", :CurrencyCode => "CNY")
                    }
                  }
                end
              }
            }

          end
        }
      }
    end

    request_xml = builder.to_xml

    BookingcomChannel.post_xml_change_set_channel(request_xml, change_set_channel, BookingcomChannel::AVAILABILITY)
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
    CtripChannel.first
  end

  def date_to_key(date)
    date.strftime('%F')
  end

end
