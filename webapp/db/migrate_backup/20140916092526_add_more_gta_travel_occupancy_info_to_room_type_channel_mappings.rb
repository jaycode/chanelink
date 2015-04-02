class AddMoreGtaTravelOccupancyInfoToRoomTypeChannelMappings < ActiveRecord::Migration
  def self.up
    add_column :room_type_channel_mappings, :gta_travel_quadruple_rate_multiplier, :decimal, :precision => 30, :scale => 20
    add_column :room_type_channel_mappings, :gta_travel_rate_basis, :integer, :default => 0
    add_column :room_type_channel_mappings, :gta_travel_max_occupancy, :integer, :default => 0
  end

  def self.down
    remove_column :room_type_channel_mappings, :gta_travel_quadruple_rate_multiplier
    remove_column :room_type_channel_mappings, :gta_travel_rate_basis
    remove_column :room_type_channel_mappings, :gta_travel_max_occupancy
  end
end
