require 'net/https'

# handler to push XML to Orbitz because of master rate changes
class OrbitzMasterRateHandler < MasterRateHandler

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

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.OTA_HotelRateAmountNotifRQ(:xmlns => OrbitzChannel::XMLNS) {
        OrbitzChannel.construct_auth_element(xml)
        xml.RateAmountMessages(:ChainCode => property_channel.orbitz_chain_code, :HotelCode => property_channel.orbitz_hotel_code) {
          change_set.logs.each do |log|
            master_rate = log.master_rate
            room_type = master_rate.room_type

            # make sure room type is allowed (has mapping)
            if room_type_ids.include?(room_type.id)
              master_rate_mapping = RoomTypeMasterRateMapping.find_by_pool_id_and_room_type_id(pool.id, room_type.id)
              
              RoomTypeMasterRateChannelMapping.find_all_by_room_type_master_rate_mapping_id_and_channel_id(master_rate_mapping.id, self.channel.id).each do |channel_mapping|
                rtcm = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(channel_mapping.room_type.id, channel.id)

                # skip if inventory 0 or does not exist
                inv = Inventory.find_by_date_and_property_id_and_pool_id_and_room_type_id(master_rate.date, property.id, pool.id, rtcm.room_type.id)
                next if inv.blank? or inv.total_rooms == 0

                xml.RateAmountMessage {
                  xml.StatusApplicationControl(:Start => date_to_key(master_rate.date), :End => date_to_key(master_rate.date), :InvCode => rtcm.orbitz_room_type_id, :RatePlanCode => rtcm.orbitz_rate_plan_id)
                  xml.Rates {
                    xml.Rate {
                      xml.BaseByGuestAmts {
                        xml.BaseByGuestAmt(:Code => OrbitzChannel::SINGLE, :AmountBeforeTax => OrbitzChannel.calculate_single_rate(rtcm, channel_mapping.apply_value(log.amount)) * channel.rate_multiplier(property) * channel.currency_converter(property))
                        xml.BaseByGuestAmt(:Code => OrbitzChannel::DOUBLE, :AmountBeforeTax => OrbitzChannel.calculate_single_rate(rtcm, channel_mapping.apply_value(log.amount)) * channel.rate_multiplier(property) * channel.currency_converter(property))
                      }
                      xml.AdditionalGuestAmounts {
                        xml.AdditionalGuestAmount(:Amount => (channel_mapping.apply_value(rtcm.orbitz_additional_guest_amount) * channel.rate_multiplier(property) * channel.currency_converter(property)), :Code => "31", :DecimalPlaces => "2")
                      }
                    }
                  }
                }
              end
              
            end
          end
        }
      }
    end

    request_xml = builder.to_xml
    OrbitzChannel.post_xml_change_set_channel(request_xml, change_set_channel)
  end

  def create_job(change_set, delay = false)
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
        if delay
          cs.delay.run
        else
          cs.run
        end
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
