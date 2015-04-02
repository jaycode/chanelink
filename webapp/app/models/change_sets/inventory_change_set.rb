# represent set of changes to inventory data
class InventoryChangeSet < ChangeSet

  has_many :logs, :class_name => "InventoryLog", :foreign_key => 'change_set_id'

  def self.create_job(logs, pool)
    unless logs.blank?
      change_set = InventoryChangeSet.create
      logs.each do |log|
        log.update_attribute(:change_set_id, change_set.id)
      end

      # determine xml channel job that want to be created
      property_channels = PropertyChannel.find_all_by_pool_id(pool.id)

      # go through each channel inventory handler and ask them to create push xml job
      property_channels.each do |pc|
        channel = pc.channel
        channel.inventory_handler.create_job(change_set) unless pc.disabled?
      end
    end
  end

  # to be used for inventory change caused by booking
  def self.create_job_for_booking(logs, pool, channel_booking_source)
    unless logs.blank?
      change_set = InventoryChangeSet.create
      logs.each do |log|
        log.update_attribute(:change_set_id, change_set.id)
      end

      # determine xml channel job that want to be created
      property_channels = PropertyChannel.find_all_by_pool_id(pool.id)

      # go through each channel inventory handler and ask them to create push xml job
      # don't do it for channel where this booking is coming from
      property_channels.each do |pc|
        channel = pc.channel
        if channel != channel_booking_source
          channel.inventory_handler.create_job(change_set)
        end
      end
    end
  end

  def property
    self.logs.first.inventory.property
  end

  def room_type_ids
    room_type_ids = Array.new
    self.logs.each do |log|
      inventory = log.inventory
      room_type_ids << inventory.room_type_id
    end
    room_type_ids.uniq
  end

  # group the logs by room type id
  def logs_organized_by_room_type_id
    result = Hash.new
    room_type_ids.each do |rt_id|
      rt_logs = Array.new
      logs.each do |inv_log|
        rt_logs << inv_log if inv_log.inventory.room_type.id == rt_id
      end
      result[rt_id] = rt_logs
    end
    result
  end
end
