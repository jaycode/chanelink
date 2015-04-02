require 'net/https'

# class to check if our push xml returns success message
class AgodaSuccessResponseChecker < SuccessResponseChecker

  def run(change_set_channel_log)
    result = false
    response_xml = change_set_channel_log.response_xml
    xml_doc  = Nokogiri::XML(response_xml)
    status_response = xml_doc.xpath("//agoda:StatusResponse", 'agoda' => AgodaChannel::XMLNS)
    # agoda is a success if it has StatusResponse and contains 200 code
    if !status_response.blank? and status_response.attr('status').to_s == AgodaChannel::SUCCESS_CODE
      result = true
    end
    result
  end

end
