require 'net/https'

# handler to push XML to Agoda because of new room type mapping created using master rate
class OrbitzMasterRateNewRoomHandler < MasterRateHandler

  def run(change_set_channel)
    change_set = change_set_channel.change_set

    # get the property of this change set
    property = change_set.logs.first.master_rate.property
    property_channel = property.channels.find_by_channel_id(channel.id)
    pool = change_set.pool
    room_type_channel_mapping = change_set.room_type_channel_mapping
    room_type = room_type_channel_mapping.room_type
    master_room_type = RoomType.find(change_set.logs.first.master_rate.room_type_id)
    master_rate_mapping = RoomTypeMasterRateMapping.find_by_pool_id_and_room_type_id(pool.id, master_room_type.id)
    channel_mapping = RoomTypeMasterRateChannelMapping.find_by_room_type_master_rate_mapping_id_and_channel_id_and_room_type_id(master_rate_mapping.id, self.channel.id, room_type.id)

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.OTA_HotelRateAmountNotifRQ(:xmlns => OrbitzChannel::XMLNS) {
        OrbitzChannel.construct_auth_element(xml)
        xml.RateAmountMessages(:ChainCode => property_channel.orbitz_chain_code, :HotelCode => property_channel.orbitz_hotel_code) {
          change_set.logs.each do |log|
            master_rate = log.master_rate

            # skip if inventory 0 or does not exist
            inv = nil
            if room_type.is_inventory_linked?
              linked = room_type.linked_room_type
              inv = Inventory.find_by_date_and_property_id_and_pool_id_and_room_type_id(master_rate.date, property.id, pool.id, linked.id)
            else
              inv = Inventory.find_by_date_and_property_id_and_pool_id_and_room_type_id(master_rate.date, property.id, pool.id, room_type_channel_mapping.room_type.id)
            end
            
            next if inv.blank? or inv.total_rooms == 0
            
            xml.RateAmountMessage {
              xml.StatusApplicationControl(:Start => date_to_key(master_rate.date), :End => date_to_key(master_rate.date), :InvCode => room_type_channel_mapping.orbitz_room_type_id, :RatePlanCode => room_type_channel_mapping.orbitz_rate_plan_id)
              xml.Rates {
                xml.Rate {
                  xml.BaseByGuestAmts {
                    xml.BaseByGuestAmt(:Code => OrbitzChannel::SINGLE, :AmountBeforeTax => OrbitzChannel.calculate_single_rate(room_type_channel_mapping, channel_mapping.apply_value(log.amount)) * channel.rate_multiplier(property) * channel.currency_converter(property))
                    xml.BaseByGuestAmt(:Code => OrbitzChannel::DOUBLE, :AmountBeforeTax => OrbitzChannel.calculate_single_rate(room_type_channel_mapping, channel_mapping.apply_value(log.amount)) * channel.rate_multiplier(property) * channel.currency_converter(property))
                  }
                  xml.AdditionalGuestAmounts {
                    xml.AdditionalGuestAmount(:Amount => (room_type_channel_mapping.orbitz_additional_guest_amount * channel.rate_multiplier(property) * channel.currency_converter(property)), :Code => "31", :DecimalPlaces => "2")
                  }
                }
              }
            }
          end
        }
      }
    end

    request_xml = builder.to_xml
    OrbitzChannel.post_xml_change_set_channel(request_xml, change_set_channel)
  end

  def create_job(change_set)
   cs = MasterRateNewRoomChangeSetChannel.create(:change_set_id => change_set.id, :channel_id => self.channel.id)
   cs.delay.run
  end

  def channel
    OrbitzChannel.first
  end

  def date_to_key(date)
    date.strftime('%F')
  end

end
