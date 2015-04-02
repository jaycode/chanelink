# class that represent history log for channel closed to business record
class GtaTravelChannelCtbLog < ActiveRecord::Base
  belongs_to :gta_travel_channel_ctb

  # helper to create channel ctb
  def self.create_gta_travel_channel_ctb_log(gta_travel_channel_ctb)
    GtaTravelChannelCtbLog.create(:gta_travel_channel_ctb_id => gta_travel_channel_ctb.id, :ctb => gta_travel_channel_ctb.ctb)
  end

end
