# represent a channel stop sell record
class ChannelStopSell < ActiveRecord::Base

  extend Unscoped

  belongs_to :property
  belongs_to :room_type
  belongs_to :pool
  belongs_to :channel

  unscope :property, :room_type, :pool

  # set this record to false
  def set_false
    ChannelStopSellLog.create(:channel_stop_sell_id => self.id, :stop_sell => false)
    self.update_attribute(:stop_sell, false)
  end
  
end
