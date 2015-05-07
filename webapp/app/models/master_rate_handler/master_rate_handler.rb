require 'singleton'

# handler to push XML because of master rate changes
class MasterRateHandler
  include Singleton

  def create_job(change_set_channel, delay = true)
    # do nothing, to be implemented by sub class
  end

end
