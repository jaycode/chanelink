require 'net/https'

# In Agoda, this is Rate Plan
class AgodaRateTypeFetcher < RateTypeFetcher
  include ChannelsHelper
  def retrieve(property)
    rate_types = Array.new
    retrieve_xml(property) do |xml_doc|
      agoda_rate_types = xml_doc.xpath('//agoda:RatePlan', 'agoda' => AgodaChannel::XMLNS)
      agoda_rate_types.each do |rt|
        # Weird exception: Name 'Nett' does not show.
        if rt.at('Name').content == '' and rt.at('ID').content == '3'
          name = 'Nett'
        else
          name = rt.at('Name').content
        end
        rate_type = RateTypeXml.new(rt.at('ID').content, name, rt.to_s)
        rate_types << rate_type
      end
    end

    rate_types
  end

  # Retrieve but in xml format
  def retrieve_xml(property, &block)
    # construct xml to request room type list
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.GetHotelRatePlansRequest('xmlns' => AgodaChannel::XMLNS) {
        # Todo: Change this to use settings i.e. property.settings(:hotel_id)
        xml.Authentication(:APIKey => AgodaChannel::API_KEY, :HotelID => property.agoda_hotel_id)
      }
    end

    request_xml = builder.to_xml
    # puts '============'
    # puts request_xml
    # puts '============'
    response_xml = AgodaChannel.post_xml(request_xml)
    # puts response_xml

    # process each room type and form it as our own object
    xml_doc  = Nokogiri::XML(response_xml)

    status_response = xml_doc.xpath('//agoda:StatusResponse', 'agoda' => AgodaChannel::XMLNS).attr('status').value

    if status_response == '200'
      block.call xml_doc
    else
      property_channel  = PropertyChannel.find_by_property_id_and_channel_id(property.id, AgodaChannel.first.id)
      logs_fetching_failure AgodaChannel.first.name, request_xml, xml_doc, property, property_channel, APP_CONFIG[:agoda_endpoint]
    end

  end

end
