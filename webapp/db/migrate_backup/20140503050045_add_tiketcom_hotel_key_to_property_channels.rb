class AddTiketcomHotelKeyToPropertyChannels < ActiveRecord::Migration
  def self.up
    add_column :property_channels, :tiketcom_hotel_key, :string
  end

  def self.down
    remove_column :property_channels, :tiketcom_hotel_key
  end
end
