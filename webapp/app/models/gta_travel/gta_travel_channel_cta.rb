# class that represent channel closed to arrival record
class GtaTravelChannelCta < ActiveRecord::Base

  extend Unscoped

  belongs_to :property
  belongs_to :pool
  belongs_to :channel

  unscope :property, :pool

  # update this record to false
  def set_false
    GtaTravelChannelCtaLog.create(:gta_travel_channel_cta_id => self.id, :cta => false)
    self.update_attribute(:cta, false)
  end
  
end
