# represent xml push of CTD data to a channel
class ChannelCtdChangeSetChannel < ChangeSetChannel

  # run the xml oush
  def run
    self.channel.channel_ctd_handler.run(self)
  end
  
end
