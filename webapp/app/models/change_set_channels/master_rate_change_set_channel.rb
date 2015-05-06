# represent xml push of master rate data to a channel
class MasterRateChangeSetChannel < ChangeSetChannel

  # run the xml push
  # Todo: Some logging is perhaps needed in this model, see InventoryNewRoomChangeSet
  #       for a sample.
  def run
    self.channel.master_rate_handler.run(self)
  end
  
end
