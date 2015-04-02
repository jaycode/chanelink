class AddGtaTravelRoomTypeIdToRoomTypeChannelMappings < ActiveRecord::Migration
  def self.up
    add_column :room_type_channel_mappings, :gta_travel_room_type_id, :string
    add_column :room_type_channel_mappings, :gta_travel_room_type_name, :string
  end

  def self.down
    remove_column :room_type_channel_mappings, :gta_travel_room_type_id
    remove_column :room_type_channel_mappings, :gta_travel_room_type_name
  end
end
