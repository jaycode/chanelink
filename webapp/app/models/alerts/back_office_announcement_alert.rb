# channel mapping approved alert
class BackOfficeAnnouncementAlert < Alert

  # to render this alert in view
  def to_display
    "<strong>Admin Alert: </strong>#{self.message}".html_safe
  end

  # to render this alert in view
  def to_display_without_style
    "Admin Alert: #{self.message}".html_safe
  end

  # create method
  def self.create_for_property(message, property)
    property.members.each do |member|
      BackOfficeAnnouncementAlert.create(:receiver_id => member.id, :property_id => property.id, :message => message)
    end
  end

  # method to send email notification
  def send_email
    AlertNotifier.delay.email_back_office_announcement(self)
  end

end