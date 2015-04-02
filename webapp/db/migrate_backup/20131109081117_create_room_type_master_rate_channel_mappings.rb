class CreateRoomTypeMasterRateChannelMappings < ActiveRecord::Migration
  def self.up
    create_table :room_type_master_rate_channel_mappings do |t|
      t.belongs_to :room_type_master_rate_mapping
      t.belongs_to :room_type
      t.belongs_to :channel
      t.string :method
      t.decimal :percentage, :precision => 8, :scale => 2
      t.decimal :value, :precision => 8, :scale => 2
      t.boolean :disabled, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :room_type_master_rate_channel_mappings
  end
end
