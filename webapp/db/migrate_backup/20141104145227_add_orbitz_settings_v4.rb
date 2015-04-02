class AddOrbitzSettingsV4 < ActiveRecord::Migration
  def self.up
    add_column :bookings, :orbitz_booking_id, :string
  end

  def self.down
    remove_column :bookings, :orbitz_booking_id
  end
end
