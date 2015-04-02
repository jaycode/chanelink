# represent xml push of master rate data to a channel
class MasterRateChangeSetChannel < ChangeSetChannel

  # run the xml push
  def run
    self.channel.master_rate_handler.run(self)
  end
  
end
