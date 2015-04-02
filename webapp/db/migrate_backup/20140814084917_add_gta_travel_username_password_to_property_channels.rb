class AddGtaTravelUsernamePasswordToPropertyChannels < ActiveRecord::Migration
  def self.up
    add_column :property_channels, :gta_travel_username, :string
    add_column :property_channels, :gta_travel_password, :string
  end

  def self.down
    remove_column :property_channels, :gta_travel_username
    remove_column :property_channels, :gta_travel_password
  end
end
