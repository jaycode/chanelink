# class that represent channel closed to arrival record
class ChannelCta < ActiveRecord::Base

  extend Unscoped

  belongs_to :property
  belongs_to :room_type
  belongs_to :pool
  belongs_to :channel

  unscope :property, :room_type, :pool

  # update this record to false
  def set_false
    ChannelCtaLog.create(:channel_cta_id => self.id, :cta => false)
    self.update_attribute(:cta, false)
  end
  
end
