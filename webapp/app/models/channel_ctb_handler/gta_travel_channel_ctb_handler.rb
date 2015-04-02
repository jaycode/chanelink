require 'net/https'

# class to handle GtaTravel push for CTB
class GtaTravelChannelCtbHandler < ChannelCtbHandler

  def run(change_set_channel)
    change_set = change_set_channel.change_set

    # get the property of this change set
    property = change_set.logs.first.gta_travel_channel_ctb.property
    property_channel = property.channels.find_by_channel_id(channel.id)

    # group ctb by value, because the XML post is different
    ctb_true = Array.new
    ctb_false = Array.new

    change_set.logs.each do |log|
      if log.ctb == true
        ctb_true << log
      else
        ctb_false << log
      end
    end

    handle_ctb_create(ctb_true, property_channel, change_set_channel)
    handle_ctb_delete(ctb_false, property_channel, change_set_channel)

  end

  # determine whether the change set relate to this channel
  def create_job(change_set)
    cs = GtaTravelChannelCtbChangeSetChannel.create(:change_set_id => change_set.id, :channel_id => self.channel.id)
    cs.delay.run
  end

  def channel
    GtaTravelChannel.first
  end

  def date_to_key(date)
    date.strftime('%F')
  end

  private

  def handle_ctb_create(ctb_true, property_channel, change_set_channel)
    return if ctb_true.blank?

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.GTA_PropertyRestrictionsCreateRQ('xmlns' => GtaTravelChannel::XMLNS, 'xmlns:xsi' => Constant::XMLNS_XSI_2001) {
        GtaTravelChannel.construct_user_element(xml)
        xml.Property(:Id => property_channel.gta_travel_property_id) {
          ctb_true.each do |log|
            channel_ctb = log.gta_travel_channel_ctb
            xml.PropertyRestriction(:StartDate => date_to_key(channel_ctb.date), :EndDate => date_to_key(channel_ctb.date), :TypeCode => GtaTravelChannel::CTB_TYPE_CODE)
          end
        }
      }
    end

    request_xml = builder.to_xml
    GtaTravelChannel.post_xml_change_set_channel(request_xml, change_set_channel, GtaTravelChannel::PROPERTY_RESTRICTIONS_CREATE)
  end

  def handle_ctb_delete(ctb_false, property_channel, change_set_channel)
    return if ctb_false.blank?

    builder = Nokogiri::XML::Builder.new do |xml|
      xml.GTA_PropertyRestrictionsDeleteRQ('xmlns' => GtaTravelChannel::XMLNS, 'xmlns:xsi' => Constant::XMLNS_XSI_2001) {
        GtaTravelChannel.construct_user_element(xml)
        xml.Property(:Id => property_channel.gta_travel_property_id) {
          ctb_false.each do |log|
            channel_ctb = log.gta_travel_channel_ctb
            xml.PropertyRestriction(:StartDate => date_to_key(channel_ctb.date), :EndDate => date_to_key(channel_ctb.date), :TypeCode => GtaTravelChannel::CTB_TYPE_CODE)
          end
        }
      }
    end

    request_xml = builder.to_xml
    GtaTravelChannel.post_xml_change_set_channel(request_xml, change_set_channel, GtaTravelChannel::PROPERTY_RESTRICTIONS_DELETE)
  end

end
