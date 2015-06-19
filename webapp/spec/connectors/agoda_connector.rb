class AgodaConnector < Connector
  def channel_class
    AgodaChannel
  end
end