class CtripConnector < Connector
  def get_rate_types()
    rate_types = CtripChannel.first.rate_type_fetcher.retrieve
    puts '============'
    puts YAML::dump(rate_types)
    puts '============'
    rate_types
  end
end