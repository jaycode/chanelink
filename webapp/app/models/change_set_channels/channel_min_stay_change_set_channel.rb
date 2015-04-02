# represent xml push of min stay data to a channel
class ChannelMinStayChangeSetChannel < ChangeSetChannel

  # run the xml oush
  def run
    self.channel.channel_min_stay_handler.run(self)
  end
  
end
