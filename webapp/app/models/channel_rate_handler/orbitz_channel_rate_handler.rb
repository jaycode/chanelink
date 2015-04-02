require 'net/https'

# class to handle Orbitz XML push for Rates
class OrbitzChannelRateHandler < ChannelRateHandler

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
    property = change_set.logs.first.channel_rate.property
    property_channel = property.channels.find_by_channel_id(channel.id)
    pool = change_set.pool

    # property room type that has mapping to this channel
    room_type_ids = Array.new
    property.room_types.each do |rt|
      room_type_ids << rt.id if rt.has_active_mapping_to_channel?(channel) and !rt.has_master_rate_mapping_to_channel?(channel, pool)
    end

    return if room_type_ids.blank?

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.OTA_HotelRateAmountNotifRQ(:xmlns => OrbitzChannel::XMLNS) {
        OrbitzChannel.construct_auth_element(xml)
        xml.RateAmountMessages(:ChainCode => property_channel.orbitz_chain_code, :HotelCode => property_channel.orbitz_hotel_code) {
          logs_to_use.each do |log|
            channel_rate = log.channel_rate
            room_type = channel_rate.room_type
            channel_mapping = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(room_type.id, channel.id)

            # make sure room type is allowed (has mapping)
            if room_type_ids.include?(room_type.id)

              xml.RateAmountMessage {
                xml.StatusApplicationControl(:Start => date_to_key(channel_rate.date), :End => date_to_key(channel_rate.date), :InvCode => channel_mapping.orbitz_room_type_id, :RatePlanCode => channel_mapping.orbitz_rate_plan_id)
                xml.Rates {
                  xml.Rate {
                    xml.BaseByGuestAmts {
                      xml.BaseByGuestAmt(:Code => OrbitzChannel::SINGLE, :AmountBeforeTax => OrbitzChannel.calculate_single_rate(channel_mapping, log.amount) * channel.rate_multiplier(property) * channel.currency_converter(property))
                      #xml.BaseByGuestAmt(:Code => OrbitzChannel::DOUBLE, :AmountBeforeTax => OrbitzChannel.calculate_double_rate(channel_mapping, log.amount) * channel.rate_multiplier(property) * channel.currency_converter(property))
                      #xml.BaseByGuestAmt(:Code => OrbitzChannel::TRIPLE, :AmountBeforeTax => (log.amount * 3))
                      #xml.BaseByGuestAmt(:Code => OrbitzChannel::QUAD, :AmountBeforeTax => (log.amount * 4))
                      #xml.BaseByGuestAmt(:Code => 'Range1', :AmountBeforeTax => 30)
                      #xml.BaseByGuestAmt(:Code => 'Range2', :AmountBeforeTax => 40)
                      #xml.BaseByGuestAmt(:Code => 'Range3', :AmountBeforeTax => 50)
                      #xml.BaseByGuestAmt(:Code => 'Senior', :AmountBeforeTax => 70)
                    }
                    xml.AdditionalGuestAmounts {
                      xml.AdditionalGuestAmount(:Amount => (channel_mapping.orbitz_additional_guest_amount * channel.rate_multiplier(property) * channel.currency_converter(property)), :Code => "31", :DecimalPlaces => "2")
                    }
                  }
                }
              }
            end
          end
        }
      }
    end
    
    request_xml = builder.to_xml
    OrbitzChannel.post_xml_change_set_channel(request_xml, change_set_channel, OrbitzChannel::OTHER)
  end

  def create_job(change_set)
   # all room types id in this change set
   room_type_ids = change_set.room_type_ids
   pool = change_set.pool
   room_type_ids.each do |rt_id|
     channel_mapping = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(rt_id, self.channel.id)
     master_rate_mapping = RoomTypeMasterRateChannelMapping.pool_id(pool.id).find_by_room_type_id_and_channel_id(rt_id, self.channel.id)
     # if room type relate the channel then run the xml push
     if !channel_mapping.blank? and master_rate_mapping.blank?
       cs = ChannelRateChangeSetChannel.create(:change_set_id => change_set.id, :channel_id => self.channel.id)
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
