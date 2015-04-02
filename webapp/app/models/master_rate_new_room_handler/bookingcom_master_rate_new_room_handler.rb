require 'net/https'

# handler to push XML to booking.com because of new room type mapping created using master rate
class BookingcomMasterRateNewRoomHandler < MasterRateHandler

  def run(change_set_channel)
    change_set = change_set_channel.change_set

    # get the property of this change set
    property = change_set.logs.first.master_rate.property
    pool = change_set.pool
    room_type_channel_mapping = change_set.room_type_channel_mapping
    room_type = room_type_channel_mapping.room_type
    master_room_type = RoomType.find(change_set.logs.first.master_rate.room_type_id)
    master_rate_mapping = RoomTypeMasterRateMapping.find_by_pool_id_and_room_type_id(pool.id, master_room_type.id)
    channel_mapping = RoomTypeMasterRateChannelMapping.find_by_room_type_master_rate_mapping_id_and_channel_id_and_room_type_id(master_rate_mapping.id, self.channel.id, room_type.id)

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.request {
        xml.username BookingcomChannel::USERNAME
        xml.password BookingcomChannel::PASSWORD
        xml.hotel_id property.bookingcom_hotel_id

        xml.room(:id => room_type_channel_mapping.bookingcom_room_type_id) {
          change_set.logs.each do |log|
            master_rate = log.master_rate
            xml.date(:value => date_to_key(master_rate.date)) {
              xml.rate(:id => room_type_channel_mapping.bookingcom_rate_plan_id)
              xml.price channel_mapping.apply_value(log.amount) * channel.rate_multiplier(property) * channel.currency_converter(property)
              xml.price1 channel_mapping.apply_value(room_type_channel_mapping.calculate_bookingcom_single_rate(log.amount)) * channel.rate_multiplier(property) * channel.currency_converter(property)
            }
          end
        }
      }
    end

    request_xml = builder.to_xml

    BookingcomChannel.post_xml_change_set_channel(request_xml, change_set_channel, BookingcomChannel::AVAILABILITY)
  end

  def create_job(change_set)
   cs = MasterRateNewRoomChangeSetChannel.create(:change_set_id => change_set.id, :channel_id => self.channel.id)
   cs.delay.run
  end

  def channel
    BookingcomChannel.first
  end

  def date_to_key(date)
    date.strftime('%F')
  end

end
