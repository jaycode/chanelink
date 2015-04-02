class CreateBookingRetrievals < ActiveRecord::Migration
  def self.up
    create_table :booking_retrievals do |t|
      t.text :request_xml, :limit => 16777215
      t.text :response_xml, :limit => 16777215
      t.string :response_code
      t.belongs_to :channel
      t.belongs_to :property
      t.timestamps
    end
  end

  def self.down
    drop_table :booking_retrievals
  end
end
