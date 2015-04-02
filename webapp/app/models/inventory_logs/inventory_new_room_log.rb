# represent every change to an inventory because of new room, basically version tracker
class InventoryNewRoomLog < InventoryLog

  def self.create_inventory_new_room_log(inventory)
    InventoryNewRoomLog.create(:inventory_id => inventory.id, :total_rooms => inventory.total_rooms)
  end
  
end
