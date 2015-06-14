class AgodaConnector < Connector
  def get_rate_types
    rate_types = AgodaChannel.first.rate_type_fetcher.retrieve(@property)
    puts '============'
    puts YAML::dump(rate_types)
    puts '============'
    rate_types
  end

  def get_room_types
    room_types = AgodaChannel.first.room_type_fetcher.retrieve(@property)
    puts '============'
    puts YAML::dump(room_types)
    puts '============'
    room_types
  end

    # from channel server
  def get_inventories(channel, pool, room_type, date_start, date_end)
    total_rooms               = Array.new
    room_type_channel_mapping = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(room_type.id, channel.id)
    rooms                = channel.inventory_handler.retrieve_by_room_type_channel_mapping(
      @property,
      room_type_channel_mapping,
      date_start,
      date_end)

    debugger
    rooms.each do |room|
    end
    
    total_rooms
  end

  def update_inventories(pool, room_type, total_rooms, date_start, date_end)
    channel = AgodaChannel.first
    # Code from inventories_controller
    logs = Array.new

    date_start.upto(date_end) do |date|

      existing_inv = Inventory.find_by_date_and_property_id_and_pool_id_and_room_type_id(date, @property.id, pool.id, room_type.id)

      # create new inventory object
      if existing_inv.blank?
        if total_rooms.blank? or total_rooms == 0
          # do nothing
          puts 'do nothing'
        elsif total_rooms.to_i > 0
          inventory               = Inventory.new
          inventory.date          = date
          inventory.total_rooms   = total_rooms
          inventory.room_type_id  = room_type.id
          inventory.property      = @property
          inventory.pool_id       = pool.id

          inventory.save

          logs << create_inventory_log(inventory)
        end
      else
        # if existing exist then do update if value is not 0
        if total_rooms.to_i >= 0 and (total_rooms.to_i != existing_inv.total_rooms.to_i)
          existing_inv.update_attribute(:total_rooms, total_rooms)
          logs << create_inventory_log(existing_inv)
        end
      end
    end

    change_set = InventoryChangeSet.create
    logs.each do |log|
      log.update_attribute(:change_set_id, change_set.id)
    end

    # # determine xml channel job that want to be created
    # property_channels = PropertyChannel.find_all_by_pool_id(pool.id)

    # # go through each channel inventory handler and ask them to create push xml job
    # property_channels.each do |pc|
    #   channel = pc.channel
    #   channel.inventory_handler.create_job(change_set) unless pc.disabled?
    # end

    # Change to..
    channel.inventory_handler.create_job(change_set, false)
  end
end