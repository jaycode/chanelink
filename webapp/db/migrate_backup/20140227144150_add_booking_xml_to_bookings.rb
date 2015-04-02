class AddBookingXmlToBookings < ActiveRecord::Migration
  def self.up
    add_column :bookings, :booking_xml, :text
  end

  def self.down
    remove_column :bookings, :booking_xml
  end
end
