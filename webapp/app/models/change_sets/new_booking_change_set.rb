class NewBookingChangeSet < ChangeSet

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

  def room_type_ids
    room_type_ids = Array.new
    self.logs.each do |log|
      inventory = log.inventory
      room_type_ids << inventory.room_type_id
    end
    room_type_ids.uniq
  end

  def property
    self.logs.first.inventory.property
  end
end
