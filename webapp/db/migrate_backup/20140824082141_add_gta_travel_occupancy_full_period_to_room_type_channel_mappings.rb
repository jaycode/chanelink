class AddGtaTravelOccupancyFullPeriodToRoomTypeChannelMappings < ActiveRecord::Migration
  def self.up
    add_column :room_type_channel_mappings, :gta_travel_single_rate_multiplier, :decimal, :precision => 8, :scale => 2
    add_column :room_type_channel_mappings, :gta_travel_double_rate_multiplier, :decimal, :precision => 8, :scale => 2
    add_column :room_type_channel_mappings, :gta_travel_triple_rate_multiplier, :decimal, :precision => 8, :scale => 2
    add_column :room_type_channel_mappings, :gta_travel_full_period, :boolean, :default => false
  end

  def self.down
    remove_column :room_type_channel_mappings, :gta_travel_single_rate_multiplier
    remove_column :room_type_channel_mappings, :gta_travel_double_rate_multiplier
    remove_column :room_type_channel_mappings, :gta_travel_triple_rate_multiplier
    remove_column :room_type_channel_mappings, :gta_travel_full_period
  end
end
