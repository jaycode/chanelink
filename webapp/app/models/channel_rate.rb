# represent channel rate record
class ChannelRate < ActiveRecord::Base

  extend Unscoped

  belongs_to :property
  belongs_to :room_type
  belongs_to :pool
  belongs_to :channel

  unscope :property, :room_type, :pool

  # set rate of this record to zero
  def set_zero
    ChannelRateLog.create(:channel_rate_id => self.id, :amount => 0)
    self.update_attribute(:amount, 0)
  end
  
end
