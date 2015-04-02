# represent xml push of channel rate data to a channel
class ChannelRateChangeSetChannel < ChangeSetChannel

  # run the xml oush
  def run
    self.channel.channel_rate_handler.run(self)
  end
  
end
