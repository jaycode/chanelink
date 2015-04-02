# represent xml push of CTB data to a channel
class GtaTravelChannelCtbChangeSetChannel < ChangeSetChannel

  # run the xml oush
  def run
    self.channel.channel_ctb_handler.run(self)
  end
  
end
