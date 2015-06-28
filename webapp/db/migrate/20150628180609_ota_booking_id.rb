class BookingId < ActiveRecord::Migration
  def self.up
    add_column :bookings, :ota_booking_id, :string
  end

  def self.down
    remove_column :bookings, :ota_booking_id
  end
end
