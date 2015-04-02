class PropertyChannelDisabledAlert < Alert
  
  # to render this alert in view
  def to_display
    property_channel = PropertyChannel.unscoped.find(self.data_id)
    I18n.t('alerts.display.property_channel_disabled_alert', :channel => property_channel.channel.name)
  end

  # create the alert for a property
  def self.create_for_property(property_channel)
    property_channel.property.members.each do |member|
      PropertyChannelDisabledAlert.create(:receiver_id => member.id, :property_id => property_channel.property.id, :data_id => property_channel.id)
    end
  end

end