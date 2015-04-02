class AddCtripSettings < ActiveRecord::Migration
  def self.up
    add_column :property_channels, :ctrip_hotel_code, :string
    add_column :property_channels, :ctrip_room_type_name, :string
    add_column :property_channels, :ctrip_room_rate_plan_category, :string
    add_column :property_channels, :ctrip_room_rate_plan_code, :string
  end

  def self.down
    remove_column :property_channels, :ctrip_hotel_code
    remove_column :property_channels, :ctrip_room_type_name
    remove_column :property_channels, :ctrip_room_rate_plan_category
    remove_column :property_channels, :ctrip_room_rate_plan_code
  end
end
