require 'net/https'

# handler to push XML to Expedia because of master rate changes
class ExpediaMasterRateHandler < MasterRateHandler

  def run(change_set_channel)
    change_set = change_set_channel.change_set

    # need to control amount of data going to expedia, divide by 150 rows each
    logs = change_set.logs

    if logs.size > ExpediaChannel::MASTER_RATE_SIZING
      logs_to_slice = Array.new(logs)
      index = 1
      # expedia has xml size limits, to divide into couple of xml fragments
      while !logs_to_slice.blank?
        logs_fragment = logs_to_slice.slice!(0, ExpediaChannel::MASTER_RATE_SIZING)
        run_by_logs(logs_fragment, change_set_channel, index)

        index = index + 1
      end
    else
      run_by_logs(logs, change_set_channel)
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
    ExpediaChannel.first
  end

  def date_to_key(date)
    date.strftime('%F')
  end

  private

  # build XML to push given log fragments
  def run_by_logs(logs_to_use, change_set_channel, fragment_id = nil)
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

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.AvailRateUpdateRQ('xmlns' => ExpediaChannel::XMLNS_AR) {
      xml.Authentication(:username => property.expedia_username, :password => property.expedia_password)
      xml.Hotel(:id => property.expedia_hotel_id)
        logs_to_use.each do |log|
          master_rate = log.master_rate
          room_type = master_rate.room_type

          # make sure room type is allowed (has mapping)
          if room_type_ids.include?(room_type.id)
            master_rate_mapping = RoomTypeMasterRateMapping.find_by_pool_id_and_room_type_id(pool.id, room_type.id)
            RoomTypeMasterRateChannelMapping.find_all_by_room_type_master_rate_mapping_id_and_channel_id(master_rate_mapping.id, self.channel.id).each do |channel_mapping|
              room_type_channel_mapping = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(channel_mapping.room_type.id, channel.id)
              xml.AvailRateUpdate {
                xml.DateRange(:from => date_to_key(master_rate.date), :to => date_to_key(master_rate.date))
                xml.RoomType(:id => room_type_channel_mapping.expedia_room_type_id) {
                  xml.RatePlan(:id => room_type_channel_mapping.expedia_rate_plan_id) {
                    xml.Rate(:currency => ExpediaChannel.get_currency(property_channel)) {
                      xml.PerDay(:rate => channel_mapping.apply_value(log.amount) * channel.rate_multiplier(property) * channel.currency_converter(property))
                    }
                  }
                }
              }
            end
          end
        end
      }
    end

    request_xml = builder.to_xml
    ExpediaChannel.post_xml_change_set_channel(request_xml, change_set_channel, ExpediaChannel::AR, fragment_id)

  end

end
