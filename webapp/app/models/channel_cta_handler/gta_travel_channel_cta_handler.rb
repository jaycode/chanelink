require 'net/https'

# class to handle GtaTravel push for CTA
class GtaTravelChannelCtaHandler < ChannelCtaHandler

  def run(change_set_channel)
    change_set = change_set_channel.change_set

    # get the property of this change set
    property = change_set.logs.first.gta_travel_channel_cta.property
    property_channel = property.channels.find_by_channel_id(channel.id)

    # group cta by value, because the XML post is different
    cta_true = Array.new
    cta_false = Array.new

    change_set.logs.each do |log|
      if log.cta == true
        cta_true << log
      else
        cta_false << log
      end
    end

    handle_cta_create(cta_true, property_channel, change_set_channel)
    handle_cta_delete(cta_false, property_channel, change_set_channel)

  end

  # determine whether the change set relate to this channel
  def create_job(change_set)
    cs = GtaTravelChannelCtaChangeSetChannel.create(:change_set_id => change_set.id, :channel_id => self.channel.id)
    cs.delay.run
  end

  def channel
    GtaTravelChannel.first
  end

  def date_to_key(date)
    date.strftime('%F')
  end

  private

  def handle_cta_create(cta_true, property_channel, change_set_channel)
    return if cta_true.blank?

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.GTA_PropertyRestrictionsCreateRQ('xmlns' => GtaTravelChannel::XMLNS, 'xmlns:xsi' => Constant::XMLNS_XSI_2001) {
        GtaTravelChannel.construct_user_element(xml)
        xml.Property(:Id => property_channel.gta_travel_property_id) {
          cta_true.each do |log|
            channel_cta = log.gta_travel_channel_cta
            xml.PropertyRestriction(:StartDate => date_to_key(channel_cta.date), :EndDate => date_to_key(channel_cta.date), :TypeCode => GtaTravelChannel::CTA_TYPE_CODE)
          end
        }
      }
    end

    request_xml = builder.to_xml
    GtaTravelChannel.post_xml_change_set_channel(request_xml, change_set_channel, GtaTravelChannel::PROPERTY_RESTRICTIONS_CREATE)
  end

  def handle_cta_delete(cta_false, property_channel, change_set_channel)
    return if cta_false.blank?

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.GTA_PropertyRestrictionsDeleteRQ('xmlns' => GtaTravelChannel::XMLNS, 'xmlns:xsi' => Constant::XMLNS_XSI_2001) {
        GtaTravelChannel.construct_user_element(xml)
        xml.Property(:Id => property_channel.gta_travel_property_id) {
          cta_false.each do |log|
            channel_cta = log.gta_travel_channel_cta
            xml.PropertyRestriction(:StartDate => date_to_key(channel_cta.date), :EndDate => date_to_key(channel_cta.date), :TypeCode => GtaTravelChannel::CTA_TYPE_CODE)
          end
        }
      }
    end

    request_xml = builder.to_xml
    GtaTravelChannel.post_xml_change_set_channel(request_xml, change_set_channel, GtaTravelChannel::PROPERTY_RESTRICTIONS_DELETE)
  end

end
