require "rails_helper"

describe "Ctrip update availabilities spec", :type => :model do
  before(:each) do
    @channel = CtripChannel.first
    @pool = pools(:default_big_hotel_1)
    @property = properties(:big_hotel_1)
    @room_type = room_types(:superior)
    @sleep_time = 20
  end

  it 'updates successfully' do
      update_inventories(@channel, @property, @pool, @room_type, 1, '2015-05-11', '2015-05-15')
  end

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
          inventory = Inventory.new
          inventory.date = date
          inventory.total_rooms = total_rooms
          inventory.room_type_id = room_type.id
          inventory.property = property
          inventory.pool_id = pool.id

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