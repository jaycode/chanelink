class CreateGtaTravelChannelCtbLogs < ActiveRecord::Migration
  def self.up
    create_table :gta_travel_channel_ctb_logs do |t|
      t.belongs_to :gta_travel_channel_ctb
      t.boolean :ctb
      t.belongs_to :change_set
      t.timestamps
    end
  end

  def self.down
    drop_table :gta_travel_channel_ctb_logs
  end
end
