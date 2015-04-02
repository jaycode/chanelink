# useful rate utilities 
class RateUtils

  # method to populate rate until the next 400 days
  def self.populate_rate_until_day_limit(rate_to_use, room_type, channel, pool, property)

    logs = Array.new
    loop_date = DateTime.now.in_time_zone.beginning_of_day

    # loop until 400th days
    while loop_date <= Constant.maximum_end_date

      channel_rate = ChannelRate.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(loop_date, property.id, pool.id, room_type.id, channel.id)

      # update if channel rate object already exist
      if !channel_rate.blank?
        channel_rate.update_attribute(:amount, rate_to_use)
        logs << create_channel_rate_log(channel_rate)
      else
        # contruct new object
        rate = ChannelRate.new
        rate.date = loop_date
        rate.amount = rate_to_use
        rate.room_type_id = room_type.id
        rate.property = property
        rate.pool = pool
        rate.channel = channel

        rate.save

        logs << create_channel_rate_log(rate)
      end
      loop_date = loop_date + 1.day
    end

    ChannelRateChangeSet.create_job(logs, pool, channel)
  end

  def self.create_channel_rate_log(channel_rate)
    ChannelRateLog.create(:channel_rate_id => channel_rate.id, :amount => channel_rate.amount)
  end

  def self.convert_to_int(value)
    value == true ? 1 : 0
  end

end
