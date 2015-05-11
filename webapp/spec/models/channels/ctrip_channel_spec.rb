require "rails_helper"

describe CtripChannel, :type => :model do
  before(:each) do
    @channel = CtripChannel.first
  end

  describe 'fetching room types' do
    it 'fetched successfully' do
      begin
        room_types = @channel.room_type_fetcher.retrieve(properties(:big_hotel_1), false, '2015-02-23', '2015-02-25')
      rescue Exception => e
        puts "Error: #{e.message}"
      end
      expect(room_types.count).to be > 0
    end
    it 'fails to fetch' do
      error = 0
      begin
        room_types = @channel.room_type_fetcher.retrieve(properties(:big_hotel_2))
      rescue Exception => e
        error = 1
        # puts "Error: #{e.message}"
      end
      expect(error).to eq 1
    end
  end

  describe 'updating inventory availabilities' do
    it 'updates successfully' do

    end
    it 'fails to update' do
    end
    def update_inventories(new_rate, date_start, date_end)
      # Code from inventories_controller
      logs = Array.new
      pool = Pool.find(params[:pool_id])

      date_start..date_end do |date|
        inventory = Inventory.new
        inventory.date = date
        inventory.total_rooms = date_inv[1]
        inventory.room_type_id = rt.id
        inventory.property = current_property
        inventory.pool_id = params[:pool_id]
      end

      change_set = InventoryChangeSet.create
      logs.each do |log|
        log.update_attribute(:change_set_id, change_set.id)
      end

      # determine xml channel job that want to be created
      property_channels = PropertyChannel.find_all_by_pool_id(pool.id)

      # go through each channel inventory handler and ask them to create push xml job
      property_channels.each do |pc|
        channel = pc.channel
        channel.inventory_handler.create_job(change_set) unless pc.disabled?
      end
    end
  end
end