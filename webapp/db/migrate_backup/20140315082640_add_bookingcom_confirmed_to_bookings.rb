class AddBookingcomConfirmedToBookings < ActiveRecord::Migration
  def self.up
    add_column :bookings, :bookingcom_confirmed, :boolean, :default => false
  end

  def self.down
    remove_column :bookings, :bookingcom_confirmed
  end
end
