class CreateBookingStatuses < ActiveRecord::Migration
  def self.up
    create_table :booking_statuses do |t|
      t.string :name
      t.timestamps
    end
    BookingStatus.create(:name => 'new')
    BookingStatus.create(:name => 'cancel')
    BookingStatus.create(:name => 'modify')
  end

  def self.down
    drop_table :booking_statuses
  end
end
