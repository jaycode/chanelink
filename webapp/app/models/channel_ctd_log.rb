# class that represent history log of channel closed to arrival record
class ChannelCtdLog < ActiveRecord::Base
  belongs_to :channel_ctd

  def self.create_channel_ctd_log(channel_ctd)
    ChannelCtdLog.create(:channel_ctd_id => channel_ctd.id, :ctd => channel_ctd.ctd)
  end
  
end
