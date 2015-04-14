class AddSettingsToRoomTypeChannelMappings < ActiveRecord::Migration
  def self.up
    add_column :room_type_channel_mappings, :settings, :string, :default => ActiveSupport::JSON.encode({})
  end

  def self.down
    remove_column :room_type_channel_mappings, :settings
  end
end
