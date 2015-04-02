class MasterRateChangeSet < ChangeSet

  has_many :logs, :class_name => "MasterRateLog", :foreign_key => 'change_set_id'

  def self.create_job(logs, pool)
    unless logs.blank?
      change_set = MasterRateChangeSet.create
      logs.each do |log|
        log.update_attribute(:change_set_id, change_set.id)
      end

      # determine xml channel job that want to be created
      property_channels = PropertyChannel.find_all_by_pool_id(pool.id)

      # go through each channel inventory handler and ask them to create push xml job
      property_channels.each do |pc|
        channel = pc.channel
        channel.master_rate_handler.create_job(change_set) unless pc.disabled?
      end
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
