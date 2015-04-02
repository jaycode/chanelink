require 'net/https'

# class to check if our push xml returns success message
class BookingcomSuccessResponseChecker < SuccessResponseChecker

  def run(change_set_channel_log)
    result = false
    response_xml = change_set_channel_log.response_xml
    xml_doc  = Nokogiri::XML(response_xml)

    # for booking.com all we need to check is 'ok' string
    ok_response = xml_doc.xpath("//ok")

    if !ok_response.blank?
      result = true
    end
    result
  end

end
