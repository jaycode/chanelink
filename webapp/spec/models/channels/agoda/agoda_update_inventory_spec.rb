require "rails_helper"
require "models/channels/agoda/agoda_spec_helper"

describe "Agoda update inventory spec", :type => :model do
  include AgodaConnector
  before(:each) do
    @channel    = AgodaChannel.first
    @pool       = pools(:default_big_hotel_1)
    @property   = properties(:big_hotel_1)
    @room_type  = room_types(:superior)
    # Since update done asynchronously, we cannot test this.
    @sleep_time = 5
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

  # create log/version for each inventory changes
  def create_inventory_log(inventory)
    MemberSetInventoryLog.create(:inventory_id => inventory.id, :total_rooms => inventory.total_rooms)
  end

end