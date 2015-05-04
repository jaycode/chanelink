# module to keep pushing min stay data for the next 400 days
class PopulateMinStayController < ApplicationController

  # module to make sure room type min stay are populated 400 days ahead
  def handle
    # go through each active room type mapping
    Property.all.each do |property|
      property = Property.active_only.first
      property.pools.each do |pool|
        PropertyChannel.find_all_by_pool_id(pool.id).each do |pc|
          channel = pc.channel

          RoomTypeChannelMapping.room_type_ids(property.room_type_ids).where(:channel_id => channel.id, :disabled => false).each do |rtm|
            populate_min_stay_channel(rtm.room_type, channel, pool, property)
          end
          
        end
      end
    end
    render :nothing => true
  end

  private

  # helper to push min stay for a given room type
  def populate_min_stay_channel(room_type, channel, pool, property)
    return if room_type.minimum_stay.blank?

    logs = Array.new
    loop_date = DateTime.now.in_time_zone.beginning_of_day

    # loop until the 400th days
    while loop_date <= Constant.maximum_end_date
      existing_min_stay = ChannelMinStay.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(loop_date, property.id, pool.id, room_type.id, channel.id)

      if existing_min_stay.blank?
        channel_min_stay = ChannelMinStay.new
        channel_min_stay.date = loop_date
        channel_min_stay.min_stay = (room_type.minimum_stay.blank? or room_type.minimum_stay == 0) ? 1 : room_type.minimum_stay
        channel_min_stay.room_type_id = room_type.id
        channel_min_stay.property = property
        channel_min_stay.pool = pool
        channel_min_stay.channel = channel

        channel_min_stay.save

        logs << create_channel_min_stay_log(channel_min_stay)
      end

      loop_date = loop_date + 1.day
    end

    ChannelMinStayChangeSet.create_job(logs, pool, channel)
  end

  def create_channel_min_stay_log(channel_min_stay)
    ChannelMinStayLog.create(:channel_min_stay_id => channel_min_stay.id, :min_stay => channel_min_stay.min_stay)
  end

end
