class AddExpediaConfirmedToBookings < ActiveRecord::Migration
  def self.up
    add_column :bookings, :expedia_confirm_number, :string
    add_column :bookings, :expedia_confirmed, :boolean, :default => false
  end

  def self.down
    remove_column :bookings, :expedia_confirm_number
    remove_column :bookings, :expedia_confirmed
  end
end
