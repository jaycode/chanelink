# represent history tracker for a channel rate record
class ChannelRateLog < ActiveRecord::Base
  belongs_to :channel_rate

  # helper to create a log
  def self.create_channel_rate_log(channel_rate)
    ChannelRateLog.create(:channel_rate_id => channel_rate.id, :amount => channel_rate.amount)
  end
  
end
