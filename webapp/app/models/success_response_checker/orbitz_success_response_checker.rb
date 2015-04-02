require 'net/https'

# class to check if our push xml returns success message
class OrbitzSuccessResponseChecker < SuccessResponseChecker

  def run(change_set_channel_log)
    result = false
    response_xml = change_set_channel_log.response_xml
    xml_doc  = Nokogiri::XML(response_xml)
    xml_doc.remove_namespaces!

    # for expedia, need to find Success element
    success = xml_doc.xpath("//Message[@messageCode = '0']")

    if !success.blank?
      result = true
    end
    result
  end

end
