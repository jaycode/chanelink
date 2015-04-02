# represent avery attempt to push data to channel
class ChangeSetChannelLog < ActiveRecord::Base
  belongs_to :change_set_channel

  after_create :check_response
  before_create :set_attempt

  # check response from channel, notify us if not success
  def check_response
    return if self.change_set_channel.blank?
    channel = self.change_set_channel.channel
    if channel.success_response_checker.run(self)
      self.update_attribute(:success, true)
    else
      TeamNotifier.delay.email_failed_xml_push(self)
    end
  end

  # set the total attempt for this log
  def set_attempt
    return if self.change_set_channel.blank?

    # check if this is fragment xml push (Expedia)
    if !self.fragment_id.blank?
      count = ChangeSetChannelLog.find_all_by_change_set_channel_id_and_fragment_id(self.change_set_channel_id, self.fragment_id).count
      self.attempt = count + 1
    else
      count = ChangeSetChannelLog.find_all_by_change_set_channel_id(self.change_set_channel_id).count
      puts "#{self.change_set_channel_id} #{ChangeSetChannelLog.find_all_by_change_set_channel_id(self.change_set_channel_id).count}"
      self.attempt = count + 1
    end
  end

end
