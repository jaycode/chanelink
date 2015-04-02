class AddFragmentIdToChangeSetChannelLogs < ActiveRecord::Migration
  def self.up
    add_column :change_set_channel_logs, :fragment_id, :integer
  end

  def self.down
    remove_column :change_set_channel_logs, :fragment_id
  end
end
