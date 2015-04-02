class AddGtaTravelBookingIdToBookings < ActiveRecord::Migration
  def self.up
    add_column :bookings, :gta_travel_booking_id, :string

  end

  def self.down
    remove_column :bookings, :gta_travel_booking_id
  end
end
