class CreateRoomTypeInventoryLinks < ActiveRecord::Migration
  def self.up
    create_table :room_type_inventory_links do |t|
      t.belongs_to :property
      t.column :room_type_from_id, :integer, :null => false, :references => :room_types
      t.column :room_type_to_id, :integer, :null => false, :references => :room_types
      t.timestamps
    end
  end

  def self.down
    drop_table :room_type_inventory_links
  end
end
