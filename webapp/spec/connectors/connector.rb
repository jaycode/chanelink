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
  def get_inventories(room_type, date_start, date_end)
    channel = channel_class.first
    channel.inventory_handler.get_inventories(
      @property,
      room_type,
      date_start,
      date_end)
  end

  def get_rates(room_type, rate_type, date_start, date_end)
    channel = channel_class.first
    # Todo: Maybe use only rate_handler instead of having
    #       master_rate_handler and channel_rate_handler?
    channel.master_rate_handler.get_rates(
      @property,
      room_type,
      rate_type,
      date_start,
      date_end)
  end

  def get_bookings(days)
    channel_class.first.booking_handler.get_bookings(@property, days)
  end

  def update_inventories(room_type, pool, total_rooms, date_start, date_end)
    channel = channel_class.first

    change_set = InventoryChangeSet.quick_update_inventories(@property, room_type, pool.id, total_rooms, date_start, date_end)

    unless change_set.blank?
      channel.inventory_handler.create_job(change_set, false)
    end
  end

  def update_rates(room_type, rate_type, pool, amount, date_start, date_end)
    channel = channel_class.first
    logs = Array.new

    # ChangeSet is like the wrapper of a set of changes.
    change_set = MasterRateChangeSet.create

    # This is similar with master_rates_controller's handle_amount.
    date_start.upto(date_end) do |date|
      existing_rate = MasterRate.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_rate_type_id(
        date, property.id, pool.id, room_type.id, rate_type.id)

      # no existing, create new master rate object
      if existing_rate.blank?
        if amount.blank? or amount == 0
          # do nothing
        elsif amount.to_f > 0
          rate = MasterRate.new
          rate.date = date
          rate.amount = amount
          rate.room_type_id = room_type.id
          rate.rate_type_id = rate_type.id
          rate.property = property
          rate.pool_id = pool.id

          rate.save
          logs << MasterRateLog.create(:master_rate_id => rate.id, :amount => rate.amount)
        end
      else
        # have existing? then just do update
        if amount.to_f >= 0 and (amount.to_f != existing_rate.amount.to_f)
          existing_rate.update_attribute(:amount, amount)
          logs << MasterRateLog.create(:master_rate_id => existing_rate.id, :amount => existing_rate.amount)
        end
      end
    end

    # Could have been prettier but for now I want to use the exact same functions
    # as used in the app. Below code are from MasterRateChangeSet model
    logs.each do |log|
      log.update_attribute(:change_set_id, change_set.id)
    end

    # This is the only thing we change to make it specific to a channel:

    #--------------------------------------------------------------------------------
    # determine xml channel job that want to be created
    # property_channels = PropertyChannel.find_all_by_pool_id(pool.id)

    # go through each channel inventory handler and ask them to create push xml job
    # property_channels.each do |pc|
    #   channel = pc.channel
    #   channel.master_rate_handler.create_job(change_set) unless pc.disabled?
    # end
    #--------------------------------------------------------------------------------

    # Change to..
    channel.master_rate_handler.create_job(change_set, false)
  end
end