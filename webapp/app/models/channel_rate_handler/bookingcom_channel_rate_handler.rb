require 'net/https'

# class to handle Booking.com XML push for Rates
class BookingcomChannelRateHandler < ChannelRateHandler

  def run(change_set_channel)
    change_set = change_set_channel.change_set

    # get the property of this change set
    property = change_set.logs.first.channel_rate.property
    pool = change_set.pool

    # property room type that has mapping to this channel
    room_type_ids = Array.new
    property.room_types.each do |rt|
      room_type_ids << rt.id if rt.has_active_mapping_to_channel?(channel) and !rt.has_master_rate_mapping_to_channel?(channel, pool)
    end

    return if room_type_ids.blank?

    logs_by_room_type = change_set.logs_organized_by_room_type_id

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.request {
        xml.username BookingcomChannel::USERNAME
        xml.password BookingcomChannel::PASSWORD
        xml.hotel_id property.bookingcom_hotel_id

        logs_by_room_type.keys.each do |rt_id|
          next unless room_type_ids.include?(rt_id)

          room_type = property.room_types.find(rt_id)
          channel_room_type_map = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(room_type.id, channel.id)
          room_type_logs = logs_by_room_type[rt_id]

          xml.room(:id => channel_room_type_map.bookingcom_room_type_id) {
            room_type_logs.each do |log|
              xml.date(:value => date_to_key(log.channel_rate.date)) {
                xml.rate(:id => channel_room_type_map.bookingcom_rate_plan_id)
                xml.price log.amount * channel.rate_multiplier(property) * channel.currency_converter(property)
                xml.price1 channel_room_type_map.calculate_bookingcom_single_rate(log.amount) * channel.rate_multiplier(property) * channel.currency_converter(property)
              }
            end
          }

        end
      }
    end

    request_xml = builder.to_xml
    
    BookingcomChannel.post_xml_change_set_channel(request_xml, change_set_channel, BookingcomChannel::AVAILABILITY)
    
  end

  def create_job(change_set)
   # all room types id in this change set
   room_type_ids = change_set.room_type_ids
   pool = change_set.pool

   room_type_ids.each do |rt_id|
     channel_mapping = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(rt_id, self.channel.id)
     master_rate_mapping = RoomTypeMasterRateChannelMapping.pool_id(pool.id).find_by_room_type_id_and_channel_id(rt_id, self.channel.id)
     puts "#{rt_id} #{!channel_mapping.blank?} #{master_rate_mapping.blank?}"
     # if room type relate the channel then run the xml push
     if !channel_mapping.blank? and master_rate_mapping.blank?
       cs = ChannelRateChangeSetChannel.create(:change_set_id => change_set.id, :channel_id => self.channel.id)
       cs.delay.run
       return
     end
   end
   
  end

  def channel
    BookingcomChannel.first
  end

  def date_to_key(date)
    date.strftime('%F')
  end

end
