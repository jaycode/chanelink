require 'singleton'

# handler to push XML because of new room type mapping created using master rate
class MasterRateNewRoomHandler
  include Singleton

  def create_job(change_set_channel)
    # do nothing, to be implemented by sub class
  end

end
