# module to populate rack rate for the 400 days forward
class PopulateRackRateController < ApplicationController

  # module to make sure room type rack rate are populated 400 days ahead
  def handle
    Property.all.each do |property|
      # go through every active room type mapping
      property.pools.each do |pool|
        PropertyChannel.find_all_by_pool_id(pool.id).each do |pc|
          channel = pc.channel

          RoomTypeChannelMapping.room_type_ids(property.room_type_ids).where(:channel_id => channel.id, :disabled => false).each do |rtm|
            populate_room_type_channel(rtm.room_type, channel, pool, property)
          end
          
        end

        RoomTypeMasterRateMapping.find_all_by_pool_id(pool.id).each do |mapping|
          populate_master_room(mapping, pool, property)
        end
      end
    end
    render :nothing => true
  end

  private

  # helper to push rates for the next 400 days
  def populate_room_type_channel(room_type, channel, pool, property)
    if !RoomTypeMasterRateChannelMapping.find_by_room_type_id_and_channel_id(room_type.id, channel.id).blank?
      # master rate channel mapping exist
      # do nothing
    else
      logs = Array.new
      loop_date = DateTime.now.in_time_zone.beginning_of_day

      # loop through until 400th days from now
      while loop_date <= Constant.maximum_end_date
        
        existing_rate = ChannelRate.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(loop_date, property.id, pool.id, room_type.id, channel.id)

        if existing_rate.blank?
          rate = ChannelRate.new
          rate.date = loop_date
          rate.amount = room_type.rack_rate
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
  end

  def create_channel_rate_log(channel_rate)
    ChannelRateLog.create(:channel_rate_id => channel_rate.id, :amount => channel_rate.amount)
  end

  def populate_master_room(master_room, pool, property)
    room_type = master_room.room_type
    logs = Array.new
    loop_date = DateTime.now.in_time_zone.beginning_of_day

    while loop_date <= Constant.maximum_end_date
      puts loop_date
      existing_rate = MasterRate.find_by_date_and_property_id_and_pool_id_and_room_type_id(loop_date, property.id, pool.id, room_type.id)

      if existing_rate.blank?
        rate = MasterRate.new
        rate.date = loop_date
        rate.amount = room_type.rack_rate
        rate.room_type_id = room_type.id
        rate.property = property
        rate.pool = pool

        rate.save
        logs << create_master_rate_log(rate)
      end

      loop_date = loop_date + 1.day
    end

    MasterRateChangeSet.create_job(logs, pool)
  end

  def create_master_rate_log(master_rate)
    MasterRateLog.create(:master_rate_id => master_rate.id, :amount => master_rate.amount)
  end

end
