class AddBookingStatusToBookings < ActiveRecord::Migration
  def self.up
    add_column :bookings, :booking_status_id, :integer, :references => :booking_statuses
  end

  def self.down
    remove_column :bookings, :booking_status_id
  end
end
