require 'singleton'

# handler to push XML because new room type mapping was created
class InventoryNewRoomHandler
  include Singleton

  def create_job(change_set_channel)
    # do nothing, to be implemented by sub class
  end

end
