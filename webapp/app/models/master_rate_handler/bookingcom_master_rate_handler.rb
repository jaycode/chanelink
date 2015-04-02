require 'net/https'

# handler to push XML to booking.com because of master rate changes
class BookingcomMasterRateHandler < MasterRateHandler

  def run(change_set_channel)
    change_set = change_set_channel.change_set

    # get the property of this change set
    property = change_set.logs.first.master_rate.property
    pool = change_set.pool

    # property room type that has mapping to this channel
    # also has master rate mapping to the pool
    room_type_ids = Array.new
    property.room_types.each do |rt|
      room_type_ids << rt.id if rt.has_master_rate_mapping?(pool) and rt.has_active_mapping_to_channel?(channel)
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

          # find the related master rate mapping, then apply the value markup 
          master_rate_mapping = RoomTypeMasterRateMapping.find_by_pool_id_and_room_type_id(pool.id, room_type.id)
          RoomTypeMasterRateChannelMapping.find_all_by_room_type_master_rate_mapping_id_and_channel_id(master_rate_mapping.id, self.channel.id).each do |channel_mapping|
            room_type_channel_mapping = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(channel_mapping.room_type_id, channel.id)
            room_type_logs = logs_by_room_type[rt_id]
            xml.room(:id => room_type_channel_mapping.bookingcom_room_type_id) {
              room_type_logs.each do |log|
                xml.date(:value => date_to_key(log.master_rate.date)) {
                  xml.rate(:id => room_type_channel_mapping.bookingcom_rate_plan_id)
                  xml.price channel_mapping.apply_value(log.amount) * channel.rate_multiplier(property) * channel.currency_converter(property)
                  xml.price1 channel_mapping.apply_value(room_type_channel_mapping.calculate_bookingcom_single_rate(log.amount)) * channel.rate_multiplier(property) * channel.currency_converter(property)
                }
              end
            }
          end

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
     puts rt_id
     # check channel mapping for room type exist
     # and check at least one master rate mapping exist
     # channel_mapping = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(rt_id, self.channel.id)
     master_rate_mapping = RoomTypeMasterRateChannelMapping.pool_id(pool.id).master_room_type_id(rt_id).find_by_channel_id(self.channel.id)
     
     unless master_rate_mapping.blank?
       cs = MasterRateChangeSetChannel.create(:change_set_id => change_set.id, :channel_id => self.channel.id)
       cs.run
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
