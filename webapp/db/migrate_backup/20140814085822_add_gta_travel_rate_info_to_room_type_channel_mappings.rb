class AddGtaTravelRateInfoToRoomTypeChannelMappings < ActiveRecord::Migration
  def self.up
    add_column :room_type_channel_mappings, :gta_travel_rate_type, :string
    add_column :room_type_channel_mappings, :gta_travel_rate_gross, :string
    add_column :room_type_channel_mappings, :gta_travel_rate_margin, :string
    add_column :room_type_channel_mappings, :gta_travel_contract_id, :string
  end

  def self.down
    remove_column :room_type_channel_mappings, :gta_travel_rate_type
    remove_column :room_type_channel_mappings, :gta_travel_rate_gross
    remove_column :room_type_channel_mappings, :gta_travel_rate_margin
    remove_column :room_type_channel_mappings, :gta_travel_contract_id
  end
end
