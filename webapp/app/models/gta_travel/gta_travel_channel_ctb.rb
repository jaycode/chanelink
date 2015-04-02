# class that represent channel closed to arrival record
class GtaTravelChannelCtb < ActiveRecord::Base

  extend Unscoped

  belongs_to :property
  belongs_to :pool
  belongs_to :channel

  unscope :property, :pool

  # update this record to false
  def set_false
    GtbTravelChannelCtaLog.create(:gta_travel_channel_ctb_id => self.id, :ctb => false)
    self.update_attribute(:ctb, false)
  end
  
end
