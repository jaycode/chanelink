# represent CTA change set
class GtaTravelChannelCtaChangeSet < ChangeSet

  has_many :logs, :class_name => "GtaTravelChannelCtaLog", :foreign_key => 'change_set_id'

  # pass is to channel cta handler
  def self.create_job(logs, pool)
    channel = GtaTravelChannel.first
    unless logs.blank?
      change_set = GtaTravelChannelCtaChangeSet.create
      logs.each do |log|
        log.update_attribute(:change_set_id, change_set.id)
      end

      pc = PropertyChannel.find_by_pool_id_and_channel_id(pool.id, channel.id)

      # pass it to channel handler for how to push the XML
      channel.channel_cta_handler.create_job(change_set) if !pc.blank? and !pc.disabled?
    end
  end

  def pool
    self.logs.first.gta_travel_channel_cta.pool
  end

  def property
    self.logs.first.gta_travel_channel_cta.property
  end

end
