class AddPaymentInfoToBookings < ActiveRecord::Migration
  def self.up
    add_column :bookings, :encrypted_cc_cvc, :string
    add_column :bookings, :encrypted_cc_expiration_date, :string
    add_column :bookings, :encrypted_cc_name, :string
    add_column :bookings, :encrypted_cc_number, :string
    add_column :bookings, :encrypted_cc_type, :string
    
  end

  def self.down
    remove_column :bookings, :encrypted_cc_cvc
    remove_column :bookings, :encrypted_cc_expiration_date
    remove_column :bookings, :encrypted_cc_name
    remove_column :bookings, :encrypted_cc_number
    remove_column :bookings, :encrypted_cc_type
  end
end
