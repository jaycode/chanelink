class CreateChannels < ActiveRecord::Migration
  def self.up
    create_table :channels do |t|
      t.string :name
      t.string :type
      t.timestamps
    end
    AgodaChannel.create(:name => 'Agoda')
    ExpediaChannel.create(:name => 'Expedia')
    BookingcomChannel.create(:name => 'Booking.com')
  end

  def self.down
    drop_table :channels
  end
end
