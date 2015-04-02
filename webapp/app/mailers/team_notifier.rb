# send email to chanelink team
class TeamNotifier < ActionMailer::Base
  
  default :from => "Chanelink <#{APP_CONFIG[:noreply_email]}>"

  def email_failed_xml_push(change_set_channel_log)
    @change_set_channel_log = change_set_channel_log
    @channel = change_set_channel_log.change_set_channel.channel
    @property = change_set_channel_log.change_set_channel.change_set.property

    mail :to => APP_CONFIG[:support_email], :subject => "Failed XML push for #{@property.name} #{@channel.name}"
  end

  def email_new_property_channel(property_channel, user)
    @property_channel = property_channel
    @user = user
    
    mail :to => user.email, :subject => "New Channel Connection Request from #{@property_channel.property.name}"
  end
  
end
