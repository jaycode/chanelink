require 'net/https'

# handler to push XML to Ctrip from master rate changes
class CtripMasterRateHandler < MasterRateHandler

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

    rate_pushed = false

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.Envelope("xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance", "xmlns:xsd" => "http://www.w3.org/2001/XMLSchema") {
        xml.parent.namespace = xml.parent.add_namespace_definition("SOAP-ENV", "http://schemas.xmlsoap.org/soap/envelope/")
        xml['SOAP-ENV'].Header
        xml['SOAP-ENV'].Body {
          xml.OTA_HotelRateAmountNotifRQ(:Version => CtripChannel::API_VERSION, :PrimaryLangID => CtripChannel::PRIMARY_LANG, :xmlns => CtripChannel::XMLNS) {
            CtripChannel.construct_authentication_element(xml)
            xml.RateAmountMessages(:HotelCode => property_channel.ctrip_hotel_code) {
              change_set.logs.each do |log|
                master_rate = log.master_rate
                room_type = master_rate.room_type

                # make sure room type is allowed (has mapping)
                if room_type_ids.include?(room_type.id)
                  master_rate_mapping = RoomTypeMasterRateMapping.find_by_pool_id_and_room_type_id(pool.id, room_type.id)

                  RoomTypeMasterRateChannelMapping.find_all_by_room_type_master_rate_mapping_id_and_channel_id(master_rate_mapping.id, self.channel.id).each do |channel_mapping|
                    rtcm = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(channel_mapping.room_type.id, channel.id)

                    # skip if inventory 0 or does not exist
                    inv = Inventory.find_by_date_and_property_id_and_pool_id_and_room_type_id(master_rate.date, property.id, pool.id, channel_mapping.room_type.id)
                    next if inv.blank? or inv.total_rooms == 0

                    rate_pushed = true

                    xml.RateAmountMessage {
                      xml.StatusApplicationControl(:RatePlanCategory => rtcm.settings(:ctrip_room_rate_plan_category), :RatePlanCode => rtcm.settings(:ctrip_room_rate_plan_code))
                      xml.Rates {
                        xml.Rate(:End => date_to_key(master_rate.date), :Start => date_to_key(master_rate.date)) {
                          xml.BaseByGuestAmts {
                            xml.BaseByGuestAmt(:Code => 'Sell', :AmountAfterTax => (log.amount * channel.rate_multiplier(property) * channel.currency_converter(property)), :CurrencyCode => "SGD")
                          }
                          xml.MealsIncluded(:Breakfast => true, :NumberOfBreakfast => 1)
                        }
                      }
                    }
                  end

                end
              end
            }
          }
        }
      }
    end

    if rate_pushed
      request_xml = builder.to_xml
      CtripChannel.post_xml_change_set_channel(request_xml, change_set_channel, CtripChannel::RATE_AMOUNT_NOTIF)
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
    CtripChannel.first
  end

  def date_to_key(date)
    date.strftime('%F')
  end

end
