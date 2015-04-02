class CreatePropertyChannels < ActiveRecord::Migration
  def self.up
    create_table :property_channels do |t|
      t.belongs_to :property
      t.belongs_to :channel
      t.belongs_to :pool

      t.decimal :rate_conversion_multiplier, :precision => 8, :scale => 2
      
      t.string :agoda_username
      t.string :agoda_password
      t.string :agoda_currency

      t.string :expedia_reservation_email_address
      t.string :expedia_modification_email_address
      t.string :expedia_cancellation_email_address
      t.string :expedia_currency

      t.string :bookingcom_username
      t.string :bookingcom_password
      t.string :bookingcom_reservation_email_address
      
      t.boolean :disabled, :default => true
      t.boolean :approved, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :property_channels
  end
end
