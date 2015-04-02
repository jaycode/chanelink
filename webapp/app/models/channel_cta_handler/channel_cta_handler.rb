# handler for each OTA on how to push xml data for cta changes
class ChannelCtaHandler
  include Singleton

  def create_job(change_set_channel)
    # do nothing, to be implemented by sub class
  end

end
