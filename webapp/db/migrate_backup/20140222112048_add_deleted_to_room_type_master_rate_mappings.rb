class AddDeletedToRoomTypeMasterRateMappings < ActiveRecord::Migration
  def self.up
    add_column :room_type_master_rate_mappings, :deleted, :boolean, :default => false
  end

  def self.down
    remove_column :room_type_master_rate_mappings, :deleted
  end
end
