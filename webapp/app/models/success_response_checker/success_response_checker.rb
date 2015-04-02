require 'singleton'

class SuccessResponseChecker
  include Singleton

  def run(change_set_channel_log)
    # do nothing, to be implemented by sub class
  end

end
