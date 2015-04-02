# represent orbitz booking data
class OrbitzBooking < Booking

  validates :orbitz_booking_id, :presence => true, :uniqueness => true

  after_create :convert_to_inventory_log

  # after create, then log the changes
  def convert_to_inventory_log
    pc = PropertyChannel.find_by_property_id_and_channel_id(self.property.id, self.channel.id)

    if self.room_type.blank?
      # we dont have the room type for this booking? just ignore
    elsif pc.blank?
      # check if orbitz belong to a pool
      # if channel does not belong to a pool for this property, just ignore
    else
      pool = pc.pool
      date_start = self.date_start
      date_end = self.date_end
      logs = Array.new

      while date_start < date_end
        inv = Inventory.find_by_date_and_room_type_id_and_pool_id(date_start, self.room_type.id, pool.id)
        if inv.blank?
          # rooms not enough, send warning
          puts 'inventory is blank'
          ZeroInventoryAlert.create_for_property(inv, self.property)
        elsif inv.total_rooms >= self.total_rooms
          inv.total_rooms = inv.total_rooms - self.total_rooms
          inv.save
          logs << create_inventory_log(inv)
        else
          inv.total_rooms = 0
          # rooms not enough, send warning
          puts 'inventory not enough'
          inv.save
          logs << create_inventory_log(inv)
          ZeroInventoryAlert.create_for_property(inv, self.property)
        end
        date_start = date_start + 1.day
      end
      InventoryChangeSet.create_job_for_booking(logs, pool, self.channel)
    end
  end

  def create_inventory_log(inventory)
    BookingInventoryLog.create(:inventory_id => inventory.id, :total_rooms => inventory.total_rooms, :booking_id => self.id)
  end

  def channel
    OrbitzChannel.first
  end
  
end

