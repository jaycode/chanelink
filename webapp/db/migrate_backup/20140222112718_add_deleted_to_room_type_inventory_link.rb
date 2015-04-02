class AddDeletedToRoomTypeInventoryLink < ActiveRecord::Migration
  def self.up
    add_column :room_type_inventory_links, :deleted, :boolean, :default => false
  end

  def self.down
    remove_column :room_type_inventory_links, :deleted
  end
end
