# sending email for alert
class AlertNotifier < ActionMailer::Base
  
  default :from => "Chanelink <#{APP_CONFIG[:noreply_email]}>"

  def email_zero_inventory(alert)
    @alert = alert
    @property = alert.property
    receiver = alert.receiver
    @receiver = receiver.name

    mail :to => receiver.email, :subject => alert.to_display
  end

  def email_property_channel_approved(alert)
    @alert = alert
    @property = alert.property
    receiver = alert.receiver
    @receiver = receiver.name

    mail :to => receiver.email, :subject => alert.to_display
  end

  def email_back_office_announcement(alert)
    @alert = alert
    @property = alert.property
    receiver = alert.receiver
    @receiver = receiver.name
    
    mail :to => receiver.email, :subject => alert.to_display_without_style
  end
  
end
