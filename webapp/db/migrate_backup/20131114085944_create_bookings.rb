class CreateBookings < ActiveRecord::Migration
  def self.up
    create_table :bookings do |t|
      t.string :type
      t.belongs_to :channel
      t.belongs_to :property
      t.belongs_to :room_type
      t.belongs_to :pool
      t.string :guest_name
      t.datetime :date_start
      t.datetime :date_end
      t.datetime :booking_date
      t.integer :total_rooms
      t.decimal :amount
      t.string :agoda_booking_id
      t.string :expedia_booking_id
      t.string :bookingcom_booking_id
      t.string :bookingcom_status
      t.timestamps
    end
  end

  def self.down
    drop_table :bookings
  end
end
