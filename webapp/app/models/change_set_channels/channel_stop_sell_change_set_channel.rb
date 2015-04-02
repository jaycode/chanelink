# represent xml push of stop sell data to a channel
class ChannelStopSellChangeSetChannel < ChangeSetChannel

  # run the xml oush
  def run
    self.channel.channel_stop_sell_handler.run(self)
  end
  
end
