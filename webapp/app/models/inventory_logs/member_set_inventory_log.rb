# represent every change to an inventory caused by members action, basically version tracker
class MemberSetInventoryLog < InventoryLog

  def self.create_inventory_log(inventory)
    MemberSetInventoryLog.create(:inventory_id => inventory.id, :total_rooms => inventory.total_rooms)
  end
  
end
