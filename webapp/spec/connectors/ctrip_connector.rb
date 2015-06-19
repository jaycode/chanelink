class CtripConnector < Connector
  def channel_class
    CtripChannel
  end

  def last_inventory_update_successful?(unique_id = '')
    channel_class.first.asynchronous_handler.last_inventory_update_result(unique_id)[:success]
  end

  def last_rate_update_successful?(unique_id = '')
    channel_class.first.asynchronous_handler.last_rate_update_result(unique_id)[:success]
  end
end