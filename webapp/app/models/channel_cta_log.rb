# class that represent history log for channel closed to arrival record
class ChannelCtaLog < ActiveRecord::Base
  belongs_to :channel_cta

  # helper to create channel cta
  def self.create_channel_cta_log(channel_cta)
    ChannelCtaLog.create(:channel_cta_id => channel_cta.id, :cta => channel_cta.cta)
  end
  
end
