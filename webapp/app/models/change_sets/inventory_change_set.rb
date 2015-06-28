# represent set of changes to inventory data
class InventoryChangeSet < ChangeSet

  has_many :logs, :class_name => "InventoryLog", :foreign_key => 'change_set_id'

  # Update several dates with one total room value
  def self.quick_update_inventories(property, room_type, pool_id, total_rooms, date_start, date_end)
    params = {"#{room_type.id}" => {}}

    date_start.upto(date_end) do |date|
      params["#{room_type.id}"][date.to_s] = total_rooms
    end

    self.update_inventories(property, pool_id, params)
  end
  # Example of params values:
  # - To update to a certain number of rooms:
  # params = {'room_type_id' => {'2015-05-27' => 10}}
  # - To add number of rooms
  # params = {'room_type_id' => {'2015-05-27' => '+10'}}
  # - To reduce number of rooms
  # params = {'room_type_id' => {'2015-05-27' => '-10'}}
  def self.update_inventories(current_property, pool_id, params)
    logs = Array.new

    # go through each value specified and save it to database
    current_property.room_types.each do |rt|
      if params["#{rt.id}"]
        params["#{rt.id}"].each do |date_inv|
          total_rooms = date_inv[1]
          existing_inv = Inventory.find_by_date_and_property_id_and_pool_id_and_room_type_id(
            date_inv[0], current_property.id, pool_id, rt.id)

          if total_rooms.class == String
            operator = total_rooms[0,1]
            if operator == '-' and !existing_inv.blank?
              total_rooms = existing_inv.total_rooms - total_rooms[1..-1].to_i
              if total_rooms < 0
                raise "Rooms not available (#{existing_inv.total_rooms} rooms left)"
              end
            elsif operator == '+' and !existing_inv.blank?
              total_rooms = existing_inv.total_rooms + total_rooms[1..-1].to_i
            elsif operator == '+' and existing_inv.blank?
              total_rooms = existing_inv.total_rooms + total_rooms[1..-1].to_i
            elsif operator == '-' and existing_inv.blank?
              total_rooms = 0
            end
          end

          # create new inventory object
          if existing_inv.blank?
            if total_rooms.blank? or total_rooms == 0
              # do nothing
            elsif total_rooms.to_i > 0
              inventory = Inventory.new
              inventory.date = date_inv[0]
              inventory.total_rooms = total_rooms
              inventory.room_type_id = rt.id
              inventory.property = current_property
              inventory.pool_id = pool_id

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
      end
    end

    change_set = nil
    # Then create InventoryChangeSet to 'wrap' those updates/creation of inventories
    #START=============================================
    unless logs.blank?
      change_set = InventoryChangeSet.create(:logs => logs)
    end
    #END===============================================
    change_set
  end

  def self.create_job(logs, pool_id)
    change_set = InventoryChangeSet.create
    logs.each do |log|
      log.update_attribute(:change_set_id, change_set.id)
    end
  end

  # to be used for inventory change caused by booking
  def self.create_job_for_booking(logs, pool, channel_booking_source)
    unless logs.blank?
      change_set = InventoryChangeSet.create
      logs.each do |log|
        log.update_attribute(:change_set_id, change_set.id)
      end

      # determine xml channel job that want to be created
      property_channels = PropertyChannel.find_all_by_pool_id(pool.id)

      # go through each channel inventory handler and ask them to create push xml job
      # don't do it for channel where this booking is coming from
      property_channels.each do |pc|
        channel = pc.channel
        if channel != channel_booking_source
          channel.inventory_handler.create_job(change_set)
        end
      end
    end
  end

  def property
    self.logs.first.inventory.property
  end

  def room_type_ids
    room_type_ids = Array.new
    self.logs.each do |log|
      inventory = log.inventory
      room_type_ids << inventory.room_type_id
    end
    room_type_ids.uniq
  end

  # group the logs by room type id
  def logs_organized_by_room_type_id
    result = Hash.new
    room_type_ids.each do |rt_id|
      rt_logs = Array.new
      logs.each do |inv_log|
        rt_logs << inv_log if inv_log.inventory.room_type.id == rt_id
      end
      result[rt_id] = rt_logs
    end
    result
  end
end
