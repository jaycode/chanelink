class CtripRateTypeFetcher < RateTypeFetcher
  def retrieve
    rate_types = Array.new
    CtripChannel::CATEGORY_MAPPING.each do |id, name|
      rate_types << RateTypeXml.new(id, name)
    end
    rate_types
  end
end
