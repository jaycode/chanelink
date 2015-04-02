class CreateGtaTravelChannelCtas < ActiveRecord::Migration
  def self.up
    create_table :gta_travel_channel_ctas do |t|
      t.datetime :date
      t.belongs_to :channel
      t.belongs_to :property
      t.belongs_to :pool
      t.boolean :cta
      t.timestamps
    end
  end

  def self.down
    drop_table :gta_travel_channel_ctas
  end
end
