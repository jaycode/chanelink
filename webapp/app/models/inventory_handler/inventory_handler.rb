require 'singleton'

class InventoryHandler
  include Singleton

  def create_job(change_set_channel)
    # do nothing, to be implemented by sub class
  end

end
