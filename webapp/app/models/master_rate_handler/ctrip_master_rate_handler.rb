require 'net/https'

# handler to push XML to Ctrip from master rate changes
class CtripMasterRateHandler < MasterRateHandler

  # Todo: Better run method with less dependency to other components
  # def run(property_id, pool_id, new_rate, start_date, end_date)
  # end

  def run(change_set_channel)
    # change_set is of class MasterRateChangeSet.
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

    prepare_rates_update_xml(room_type_ids, change_set, property, pool) do |rates_sent, builder|
      if rates_sent
        request_xml = builder.to_xml
        response = CtripChannel.post_xml_change_set_channel(request_xml, change_set_channel, APP_CONFIG[:ctrip_rates_update_endpoint])
        response_xml  = response.gsub(/xmlns=\"([^\"]*)\"/, "")
        xml_doc       = Nokogiri::XML(response_xml)
        unique_id     = xml_doc.xpath("//UniqueID")
        return {:unique_id => unique_id.first.attr('ID'), :type => unique_id.first.attr('Type')}
      else
        logs_rate_update_failure CtripChannel.first.name, property, property_channel, APP_CONFIG[:ctrip_inventories_update_endpoint]
      end
    end

  end

  def prepare_rates_update_xml(room_type_ids, change_set, property, pool, &block)
    rates_sent = false
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.Envelope("xmlns:xsi" => CtripChannel::XMLNS_XSI, "xmlns:xsd" => CtripChannel::XMLNS_XSD) {
        xml.parent.namespace = xml.parent.add_namespace_definition("SOAP-ENV", CtripChannel::SOAP_ENV)
        xml['SOAP-ENV'].Header
        xml['SOAP-ENV'].Body {
          xml.OTA_HotelRateAmountNotifRQ(:Version => CtripChannel::API_VERSION, :PrimaryLangID => CtripChannel::PRIMARY_LANG, :xmlns => CtripChannel::XMLNS) {
            CtripChannel.construct_authentication_element(xml, property)
            xml.RateAmountMessages(:HotelCode => property.settings(:ctrip_hotel_id)) {
              room_type_ids.each do |room_type_id|
                master_rate_mapping = RoomTypeMasterRateMapping.find_by_pool_id_and_room_type_id(pool.id, room_type_id)

                # make sure room type is allowed (has mapping)
                RoomTypeMasterRateChannelMapping.find_all_by_room_type_master_rate_mapping_id_and_channel_id(master_rate_mapping.id, self.channel.id).each do |channel_mapping|
                  rtcm = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(room_type_id, channel.id)
                  xml.RateAmountMessage() {
                    xml.StatusApplicationControl(:RatePlanCategory => rtcm.ota_rate_type_id,
                                                 :RatePlanCode => rtcm.ota_room_type_id)
                    xml.Rates {
                      change_set.logs.each do |log|
                        master_rate = log.master_rate
                        room_type = master_rate.room_type

                        # Todo: Solve this, why does the old code not want to change the rate when inventory is 0?
                        #
                        # skip if inventory 0 or does not exist
                        # inv = Inventory.find_by_date_and_property_id_and_pool_id_and_room_type_id(master_rate.date, property.id, pool.id, channel_mapping.room_type.id)
                        # next if inv.blank? or inv.total_rooms == 0

                        rates_sent = true
                        xml.Rate(:Start => master_rate.date.strftime('%Y-%m-%d'), :End => master_rate.date.strftime('%Y-%m-%d')) {
                          xml.BaseByGuestAmts {
                            xml.BaseByGuestAmt(
                              :Code => 'Sell',
                              :AmountAfterTax => (log.amount * channel.rate_multiplier(property) * channel.currency_converter(property)),
                              :CurrencyCode => rtcm.settings(:ctrip_currency_code)
                            )
                          }
                          xml.MealsIncluded(:Breakfast => rtcm.settings(:ctrip_breakfast_inclusion), :NumberOfBreakfast => rtcm.settings(:ctrip_number_of_breakfast))
                        }
                      end
                    }
                  }
                end
              end
            }
          }
        }
      }
    end

    block.call(rates_sent, builder)
  end

  # This method creates several change_set_channels,
  # one for each set of room type, change set, and channel.
  def create_job(change_set, delay = true)
    result = {}
    create_change_set_channel(change_set) do |cs|
      if delay
        result = cs.delay.run
      else
        result = cs.run
      end
    end
    result
  end

  # Create a single master rate change set channel for given change set.
  def create_change_set_channel(change_set, &foreach_block)
    # all room types id in this change set
    room_type_ids = change_set.room_type_ids
    pool = change_set.pool

    room_type_ids.each do |rt_id|
      # check channel mapping for room type exist
      # and check at least one master rate mapping exist
      # channel_mapping = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(rt_id, self.channel.id)
      master_rate_mapping = RoomTypeMasterRateChannelMapping.pool_id(pool.id).
        master_room_type_id(rt_id).
        find_by_channel_id(self.channel.id)

      unless master_rate_mapping.blank?
        cs = MasterRateChangeSetChannel.create(
          :change_set_id => change_set.id,
          :channel_id => self.channel.id)
        foreach_block.call(cs)
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
