require 'singleton'

class InventoryHandler
  include Singleton
  include ChannelsHelper

  def get_inventories(property, room_type, date_start, date_end, rate_type = nil)
    get_inventories_xml(property, room_type, date_start, date_end, rate_type) do |xml_doc|

    end
  end

  def get_inventories_xml(property, room_type, date_start, date_end, rate_type = nil)
    # Override this in subclasses.
  end

  # This is the method that sends inventory update request
  def create_job(change_set, delay = true)
    # all room types id in this change set
    # room_type_ids = change_set.room_type_ids

    cs = InventoryChangeSetChannel.create(:change_set_id => change_set.id, :channel_id => self.channel.id)
    if delay
      cs.delay.run
    else
      cs.run
    end
  end

end
