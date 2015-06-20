class Connector
  attr_reader :property

  def initialize(property)
    @property = property
  end

  def set_property(property)
    @property = property
  end

  def get_rate_types
    channel_class.first.rate_type_fetcher.retrieve(@property)
  end

  def get_room_types(exclude_mapped_rooms = false)
    channel_class.first.room_type_fetcher.retrieve(@property, exclude_mapped_rooms)
  end

  # Get inventories from channel server
  def get_inventories(room_type, date_start, date_end, rate_type)
    channel = channel_class.first
    channel.inventory_handler.get_inventories(
      @property,
      room_type,
      date_start,
      date_end,
      rate_type)
  end

  def get_bookings(days)
    channel_class.booking_handler.retrieve(days)
  end

  def update_inventories(room_type, pool, total_rooms, date_start, date_end, rate_type = nil)
    if rate_type.nil?
      rate_type = RateType.where('account_id IS NULL').first
    end
    channel = channel_class.first
    # Code from inventories_controller
    logs = Array.new

    # First create or update all required inventories.
    #START=============================================
    date_start.upto(date_end) do |date|

      existing_inv = Inventory.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_rate_type_id(
        date, @property.id, pool.id, room_type.id, rate_type.id)

      # create new inventory object
      if existing_inv.blank?
        if total_rooms.blank? or total_rooms == 0
          # do nothing
        elsif total_rooms.to_i > 0
          inventory               = Inventory.new
          inventory.date          = date
          inventory.total_rooms   = total_rooms
          inventory.room_type_id  = room_type.id
          inventory.property      = @property
          inventory.pool_id       = pool.id
          inventory.rate_type_id  = rate_type.id

          inventory.save

          logs << MemberSetInventoryLog.create(:inventory_id => inventory.id, :total_rooms => inventory.total_rooms)
        end
      else
        # if existing exist then do update if value is not 0
        if total_rooms.to_i >= 0 and (total_rooms.to_i != existing_inv.total_rooms.to_i)
          existing_inv.update_attribute(:total_rooms, total_rooms)
          logs << MemberSetInventoryLog.create(:inventory_id => existing_inv.id, :total_rooms => existing_inv.total_rooms)
        end
      end
    end
    #END===============================================

    # Then create InventoryChangeSet to 'wrap' those updates/creation of inventories
    #START=============================================
    unless logs.blank?
      change_set = InventoryChangeSet.create
      logs.each do |log|
        log.update_attribute(:change_set_id, change_set.id)
      end
    end
    #END===============================================

    # Then send the xml. In inventories controller, this creates a delayed job,
    # but in here we directly run the job.
    #START=============================================

    # # determine xml channel job that want to be created
    # property_channels = PropertyChannel.find_all_by_pool_id(pool.id)

    # # go through each channel inventory handler and ask them to create push xml job
    # property_channels.each do |pc|
    #   channel = pc.channel
    #   channel.inventory_handler.create_job(change_set) unless pc.disabled?
    # end

    # Change to..
    channel.inventory_handler.create_job(change_set, false)
    #END===============================================
  end
end