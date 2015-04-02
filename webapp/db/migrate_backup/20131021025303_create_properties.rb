class CreateProperties < ActiveRecord::Migration
  def self.up
    create_table :properties do |t|
      t.string :name
      t.text :address
      t.string :city
      t.string :state
      t.string :postcode
      t.decimal :minimum_room_rate, :precision => 8, :scale => 2
      t.belongs_to :country
      t.belongs_to :account
      t.string :agoda_hotel_id
      t.string :expedia_hotel_id
      t.string :expedia_username
      t.string :expedia_password
      t.string :bookingcom_hotel_id
      t.string :bookingcom_username
      t.string :bookingcom_password
      t.boolean :approved, :default => false
      t.belongs_to :currency
      t.timestamps
    end

    add_index(:properties, :id, :unique => true)
  end

  def self.down
    drop_table :properties
  end
end
