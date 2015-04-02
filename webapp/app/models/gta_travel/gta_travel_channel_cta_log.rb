# class that represent history log for channel closed to arrival record
class GtaTravelChannelCtaLog < ActiveRecord::Base
  belongs_to :gta_travel_channel_cta

  # helper to create channel cta
  def self.create_gta_travel_channel_cta_log(gta_travel_channel_cta)
    GtaTravelChannelCtaLog.create(:gta_travel_channel_cta_id => gta_travel_channel_cta.id, :cta => gta_travel_channel_cta.cta)
  end
  
end
