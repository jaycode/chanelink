# represent channel min stay record
class ChannelMinStay < ActiveRecord::Base

  extend Unscoped

  belongs_to :property
  belongs_to :room_type
  belongs_to :pool
  belongs_to :channel

  unscope :property, :room_type, :pool

  # set this record to zero
  def set_zero
    ChannelMinStayLog.create(:channel_min_stay_id => self.id, :min_stay => 0)
    self.update_attribute(:min_stay, 0)
  end
  
end
