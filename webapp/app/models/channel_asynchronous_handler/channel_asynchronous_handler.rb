require 'singleton'

class ChannelAsynchronousHandler
  include Singleton

  def run(unique_id, type)
    # do nothing, to be implemented by sub class
  end

end
