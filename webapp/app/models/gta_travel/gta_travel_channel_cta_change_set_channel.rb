# represent xml push of CTA data to a channel
class GtaTravelChannelCtaChangeSetChannel < ChangeSetChannel

  # run the xml oush
  def run
    self.channel.channel_cta_handler.run(self)
  end
  
end
