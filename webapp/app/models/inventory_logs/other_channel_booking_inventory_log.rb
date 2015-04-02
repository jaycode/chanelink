# currently not used
class OtherChannelBookingInventoryLog < InventoryLog

  belongs_to :booking

  def self.convert_from_booking_inventory_logs(logs, pool)
    result = Array.new
    logs.each do |log|
      booking_inv = log.inventory
      inv = Inventory.find_by_date_and_room_type_id_and_pool_id(booking_inv.date, booking_inv.room_type.id, pool.id)

      if inv.blank?
        # rooms not enough, send warning
        puts 'inventory is blank'
      elsif inv.total_rooms >= booking_inv.total_rooms
        inv.total_rooms = inv.total_rooms - booking_inv.total_rooms
        inv.save
        logs << create_log(inv, log)
      else
        inv.total_rooms = 0
        # rooms not enough, send warning
        puts 'inventory not enough'
        inv.save
        logs << create_log(inv, log)
      end
    end
    result
  end

  private

  def self.create_log(inv, booking_log)
    OtherChannelBookingInventoryLog.create(:inventory_id => inv.id, :total_rooms => booking_log.total_rooms, :booking_id => booking_log.booking_id)
  end
  
end
