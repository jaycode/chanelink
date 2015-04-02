# history tracker for channel stop sell record
class ChannelStopSellLog < ActiveRecord::Base
  belongs_to :channel_stop_sell

  def self.create_channel_stop_sell_log(channel_stop_sell)
    ChannelStopSellLog.create(:channel_stop_sell_id => channel_stop_sell.id, :stop_sell => channel_stop_sell.stop_sell)
  end
  
end
