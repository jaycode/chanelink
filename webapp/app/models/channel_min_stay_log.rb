# represent a history log for channel min stay record
class ChannelMinStayLog < ActiveRecord::Base
  belongs_to :channel_min_stay

  def self.create_channel_min_stay_log(channel_min_stay)
    ChannelMinStayLog.create(:channel_min_stay_id => channel_min_stay.id, :min_stay => channel_min_stay.min_stay)
  end
  
end
