class CreateChangeSetChannelLogs < ActiveRecord::Migration
  def self.up
    create_table :change_set_channel_logs do |t|
      t.belongs_to :change_set_channel
      t.text :request_xml, :limit => 16777215
      t.text :response_xml, :limit => 16777215
      t.string :response_code
      t.boolean :success, :default => false
      t.integer :attempt
      t.timestamps
    end
  end

  def self.down
    drop_table :change_set_channel_logs
  end
end
