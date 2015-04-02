# represent xml push of inventory data to a channel
class InventoryChangeSetChannel < ChangeSetChannel

  # run the xml oush
  def run
    self.channel.inventory_handler.run(self)
  end
  
end
