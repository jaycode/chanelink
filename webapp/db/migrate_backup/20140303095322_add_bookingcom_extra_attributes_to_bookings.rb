class AddBookingcomExtraAttributesToBookings < ActiveRecord::Migration
  def self.up
    add_column :bookings, :bookingcom_room_xml, :text
    add_column :bookings, :bookingcom_room_reservation_id, :string
  end

  def self.down
    remove_column :bookings, :bookingcom_room_xml
    remove_column :bookings, :bookingcom_room_reservation_id
  end
end
