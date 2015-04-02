class AddUuidToBookings < ActiveRecord::Migration
  def self.up
    add_column :bookings, :uuid, :string
  end

  def self.down
    remove_column :bookings, :uuid
  end
end
