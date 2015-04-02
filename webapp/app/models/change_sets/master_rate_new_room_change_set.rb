class MasterRateNewRoomChangeSet < ChangeSet

  has_many :logs, :class_name => "MasterRateNewRoomLog", :foreign_key => 'change_set_id'
  belongs_to :room_type_channel_mapping

  def self.create_job(logs, pool, channel, room_type_channel_mapping)
    unless logs.blank?
      change_set = MasterRateNewRoomChangeSet.create(:room_type_channel_mapping_id => room_type_channel_mapping.id)
      logs.each do |log|
        log.update_attribute(:change_set_id, change_set.id)
      end

      pc = PropertyChannel.find_by_pool_id_and_channel_id(pool.id, channel.id)

      # pass it to channel handler for how to push the XML
      channel.master_rate_new_room_handler.create_job(change_set) if !pc.blank? and !pc.disabled?
    end
  end

  def pool
    self.logs.first.master_rate.pool
  end

  def property
    self.logs.first.master_rate.property
  end

  def room_type_ids
    room_type_ids = Array.new
    self.logs.each do |log|
      master_rate = log.master_rate
      room_type_ids << master_rate.room_type_id
    end
    room_type_ids.uniq
  end

  # group the change set logs by room type id
  def logs_organized_by_room_type_id
    result = Hash.new
    room_type_ids.each do |rt_id|
      rt_logs = Array.new
      logs.each do |master_rate_log|
        rt_logs << master_rate_log if master_rate_log.master_rate.room_type.id == rt_id
      end
      result[rt_id] = rt_logs
    end
    result
  end
end
