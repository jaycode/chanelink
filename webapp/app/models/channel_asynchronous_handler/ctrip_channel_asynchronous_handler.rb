require 'net/https'

# class to handle Ctrip asynchronous
class CtripChannelAsynchronousHandler < ChannelAsynchronousHandler

  def prepare_xml(unique_id, type, &block)
    request_sent = false

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.Envelope("xmlns:xsi" => CtripChannel::XMLNS_XSI, "xmlns:xsd" => CtripChannel::XMLNS_XSD) {
        xml.parent.namespace = xml.parent.add_namespace_definition("SOAP-ENV", CtripChannel::SOAP_ENV)
        xml['SOAP-ENV'].Header
        xml['SOAP-ENV'].Body {
          xml.OTA_NotifReportRQ(:Version => CtripChannel::API_VERSION, :PrimaryLangID => CtripChannel::PRIMARY_LANG, :xmlns => CtripChannel::XMLNS) {
            xml.UniqueID(:ID => unique_id, :Type => type) {

              request_sent = true

            }
          }
        }
      }
    end

    block.call(request_sent, builder)
  end

  def run(unique_id, type)
    prepare_xml(unique_id, type) do |request_sent, builder|
      if request_sent
        request_xml   = builder.to_xml
        response      = CtripChannel.post_xml(request_xml, APP_CONFIG[:ctrip_asynchronous_endpoint])
        response_xml  = response.gsub(/xmlns=\"([^\"]*)\"/, "")
        puts YAML::dump(response_xml)
        xml_doc       = Nokogiri::XML(response_xml)
        success       = xml_doc.xpath("//Success")
        warnings      = xml_doc.xpath("//Warnings")
        errors        = xml_doc.xpath("//Errors")

        return {:success => (success.count > 0 ? true : false), :warnings => (warnings.count > 0 ? true : false), :errors => (errors.count > 0 ? true : false)}
      else
        puts 'Check asynchronous failed.'
        return {:success => false, :warnings => false, :errors => true}
      end
    end
  end

  def channel
    CtripChannel.first
  end
end
