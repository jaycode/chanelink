# represent xml push of master rate data to a channel
class MasterRateNewRoomChangeSetChannel < ChangeSetChannel

  # run the xml push
  def run
    self.channel.master_rate_new_room_handler.run(self)
  end
  
end
