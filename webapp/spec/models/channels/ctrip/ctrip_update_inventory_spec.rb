require "rails_helper"

describe "Ctrip update inventory spec", :type => :model do

  before(:each) do
    @channel    = CtripChannel.first
    @pool       = pools(:default_big_hotel_1)
    @property   = properties(:big_hotel_1)
    @room_type  = room_types(:superior)
    # Since update done asynchronously, we cannot test this.
    # @sleep_time = 20
  end

  it 'updates successfully' do
    date_start                = Date.today + 1.weeks
    date_end                  = Date.today + 2.weeks
    total_rooms_alternatives  = [6, 7]
    total_rooms_before        = get_inventories(@channel, @property, @pool, @room_type, date_start, date_end)

    if total_rooms_before[0] == total_rooms_alternatives[0]
      update            = update_inventories(@channel, @property, @pool, @room_type, total_rooms_alternatives[1], date_start, date_end)
      check_asynchronous(@channel, update[:unique_id], update[:type]);
      total_rooms_after = get_inventories(@channel, @property, @pool, @room_type, date_start, date_end)
      total_rooms_after.each do |total_rooms|
        expect(total_rooms).to eq total_rooms_alternatives[1]
      end
    else
      update            = update_inventories(@channel, @property, @pool, @room_type, total_rooms_alternatives[0], date_start, date_end)
      check_asynchronous(@channel, update[:unique_id], update[:type]);
      total_rooms_after = get_inventories(@channel, @property, @pool, @room_type, date_start, date_end)
      total_rooms_after.each do |total_rooms|
        expect(total_rooms).to eq total_rooms_alternatives[0]
      end
    end

  end

  def check_asynchronous(channel, unique_id, type)
    flag_result = false
    flag_processing = true
    while flag_processing  do
      flag_result = channel.asynchronous_handler.run(unique_id, type)
      if flag_result[:success] || flag_result[:errors]
        flag_processing = false
      else
        puts YAML::dump(flag_result)
        puts 'sleep'
        sleep(@sleep_time)
      end
    end
    return flag_result
  end

  # from ctrip server
  def get_inventories(channel, property, pool, room_type, date_start, date_end)
    total_rooms               = Array.new
    room_type_channel_mapping = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(room_type.id, channel.id)
    room_types                = channel.room_type_fetcher.retrieve_by_rate_plan_code(property, room_type_channel_mapping.settings(:ctrip_room_rate_plan_code), date_start, date_end)

    room_type = nil
    room_types.each do |room_type|
      if room_type.rate_plan_category == room_type_channel_mapping.settings(:ctrip_room_rate_plan_category)
        room_type.rates.each do |rate|
          total_rooms << rate.number_of_units.to_i
        end
      end
    end
    
    total_rooms
  end

  # from local db
  # def get_inventories(channel, property, pool, room_type, date_start, date_end)
  #   total_rooms = Array.new

  #   date_start.upto(date_end) do |date|
  #     inventory = Inventory.find_by_date_and_property_id_and_pool_id_and_room_type_id(date, property.id, pool.id, room_type.id)
  #     if inventory.blank?
  #       total_rooms << 0
  #     else
  #       total_rooms << inventory.total_rooms
  #     end
  #   end

  #   total_rooms
  # end

  def update_inventories(channel, property, pool, room_type, total_rooms, date_start, date_end)
    # Code from inventories_controller
    logs = Array.new

    date_start.upto(date_end) do |date|

      existing_inv = Inventory.find_by_date_and_property_id_and_pool_id_and_room_type_id(date, property.id, pool.id, room_type.id)

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
          inventory.property      = property
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

  # create log/version for each inventory changes
  def create_inventory_log(inventory)
    MemberSetInventoryLog.create(:inventory_id => inventory.id, :total_rooms => inventory.total_rooms)
  end

end