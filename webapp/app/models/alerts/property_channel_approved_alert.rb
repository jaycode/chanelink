# channel mapping approved alert
class PropertyChannelApprovedAlert < Alert

  # to render this alert in view
  def to_display
    property_channel = PropertyChannel.unscoped.find(self.data_id)
    I18n.t('alerts.display.property_channel_approved_alert', :channel => property_channel.channel.name)
  end

  # create method
  def self.create_for_property(property_channel, property)
    property.members.each do |member|
      PropertyChannelApprovedAlert.create(:receiver_id => member.id, :property_id => property.id, :data_id => property_channel.id)
    end
  end

  # resend email for this alert
  def self.resend_email(property)
    # resend to all members
    property.members.each do |member|
      property.channels.each do |pc|
        pca = PropertyChannelApprovedAlert.find_by_receiver_id_and_data_id(member.id, pc.id)
        pca.send_email if !pca.blank?
      end
    end
  end

  # method to send email notification
  def send_email
    if PropertyChannel.unscoped.find(self.data_id).property.account.approved?
      AlertNotifier.delay.email_property_channel_approved(self)
    end
  end

end