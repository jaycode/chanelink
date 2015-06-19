require 'net/https'

# class to handle Ctrip asynchronous
class CtripChannelAsynchronousHandler < ChannelAsynchronousHandler

  def last_inventory_update_result(unique_id)
    last_update_result unique_id, '505'
  end

  def last_rate_update_result(unique_id)
    last_update_result unique_id, '506'
  end

  def last_update_result(unique_id = '', type = '505')
    # construct xml to request room type list
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.Envelope("xmlns:xsi" => CtripChannel::XMLNS_XSI, "xmlns:xsd" => CtripChannel::XMLNS_XSD) {
        xml.parent.namespace = xml.parent.add_namespace_definition("SOAP-ENV", CtripChannel::SOAP_ENV)
        xml['SOAP-ENV'].Header
        xml['SOAP-ENV'].Body {
          xml.OTA_NotifReportRQ(:Version => CtripChannel::API_VERSION,
                                :PrimaryLangID => CtripChannel::PRIMARY_LANG,
                                :xmlns => CtripChannel::XMLNS) {
            xml.UniqueID(:ID => unique_id, :Type => type)
          }
        }
      }
    end
    request_xml   = builder.to_xml
    response_xml  = CtripChannel.post_xml(request_xml, APP_CONFIG[:ctrip_asynchronous_endpoint])
    response_xml  = response_xml.gsub(/xmlns=\"([^\"]*)\"/, "")

    # puts '============'
    # puts YAML::dump(request_xml)
    # puts '============'

    xml_doc = Nokogiri::XML(response_xml)
    success = xml_doc.xpath("//Success")
    s = success.count > 0
    m = ''
    unless s
      unless xml_doc.xpath('//Error').blank?
        m = xml_doc.xpath('//Error').text
      end
      unless xml_doc.xpath('//Warning').blank?
        if xml_doc.xpath('//Warning').attr('Type').value == '3'
          # This means "waiting for processing"
          s = true
        end
        m = xml_doc.xpath('//Warning').attr('ShortText').text
      end
    end
    {:success => s, :message => m}
  end
end
