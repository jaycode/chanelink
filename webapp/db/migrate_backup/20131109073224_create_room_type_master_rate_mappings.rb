class CreateRoomTypeMasterRateMappings < ActiveRecord::Migration
  def self.up
    create_table :room_type_master_rate_mappings do |t|
      t.belongs_to :pool
      t.belongs_to :room_type
      t.timestamps
    end
  end

  def self.down
    drop_table :room_type_master_rate_mappings
  end
end
