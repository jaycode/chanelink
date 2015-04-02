class CreateGtaTravelChannelCtaLogs < ActiveRecord::Migration
  def self.up
    create_table :gta_travel_channel_cta_logs do |t|
      t.belongs_to :gta_travel_channel_cta
      t.boolean :cta
      t.belongs_to :change_set
      t.timestamps
    end
  end

  def self.down
    drop_table :gta_travel_channel_cta_logs
  end
end
