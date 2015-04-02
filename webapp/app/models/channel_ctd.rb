# class that represent channel closed to departure record
class ChannelCtd < ActiveRecord::Base

  extend Unscoped

  belongs_to :property
  belongs_to :room_type
  belongs_to :pool
  belongs_to :channel

  unscope :property, :room_type, :pool

  # set this record to false
  def set_false
    ChannelCtdLog.create(:channel_ctd_id => self.id, :ctd => false)
    self.update_attribute(:ctd, false)
  end
  
end
