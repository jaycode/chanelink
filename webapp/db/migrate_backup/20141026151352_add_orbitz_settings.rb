class AddOrbitzSettings < ActiveRecord::Migration
  def self.up
    add_column :property_channels, :orbitz_hotel_code, :string
    add_column :property_channels, :orbitz_chain_code, :string
    add_column :room_type_channel_mappings, :orbitz_room_type_id, :string
    add_column :room_type_channel_mappings, :orbitz_room_type_name, :string
  end

  def self.down
    remove_column :property_channels, :orbitz_hotel_code
    remove_column :property_channels, :orbitz_chain_code
    remove_column :room_type_channel_mappings, :orbitz_room_type_id
    remove_column :room_type_channel_mappings, :orbitz_room_type_name
  end
end
