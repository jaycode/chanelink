# represent xml push of inventory data to a channel
class InventoryChangeSetChannel < ChangeSetChannel

  # run the xml oush
  def run
    self.channel.inventory_handler.run(self)
    cs = InventoryChangeSetChannel.create(:change_set_id => change_set.id, :channel_id => channels(:agoda).id)
  end
  
end
