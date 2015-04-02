# represent CTA change set
class ChannelCtaChangeSet < ChangeSet

  has_many :logs, :class_name => "ChannelCtaLog", :foreign_key => 'change_set_id'

  # pass is to channel cta handler
  def self.create_job(logs, pool, channel)
    unless logs.blank?
      change_set = ChannelCtaChangeSet.create
      logs.each do |log|
        log.update_attribute(:change_set_id, change_set.id)
      end

      pc = PropertyChannel.find_by_pool_id_and_channel_id(pool.id, channel.id)

      # pass it to channel handler for how to push the XML
      channel.channel_cta_handler.create_job(change_set) if !pc.blank? and !pc.disabled?
    end
  end

  def pool
    self.logs.first.channel_cta.pool
  end

  def property
    self.logs.first.channel_cta.property
  end

  def room_type_ids
    room_type_ids = Array.new
    self.logs.each do |log|
      channel_cta = log.channel_cta
      room_type_ids << channel_cta.room_type_id
    end
    room_type_ids.uniq
  end

  # group the change set logs by room type id
  def logs_organized_by_room_type_id
    result = Hash.new
    room_type_ids.each do |rt_id|
      rt_logs = Array.new
      logs.each do |cta_log|
        rt_logs << cta_log if cta_log.channel_cta.room_type.id == rt_id
      end
      result[rt_id] = rt_logs
    end
    result
  end
end
