require "rails_helper"

describe "Expedia get inventory spec", :type => :model do

  before(:each) do
    @channel    = ExpediaChannel.first
    @pool       = pools(:default_big_hotel_1)
    @property   = properties(:big_hotel_1)
    @room_type  = room_types(:superior)
  end

  it 'gets inventory availabilities successfully' do
    date_start                = Date.today + 1.weeks
    date_end                  = Date.today + 2.weeks
    total_rooms_alternatives  = [6, 7]
    total_rooms_before        = get_inventories(@channel, @property, @pool, @room_type, date_start, date_end)
  end

  # from channel server
  def get_inventories(channel, property, pool, room_type, date_start, date_end)
    room_type_channel_mapping = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(room_type.id, channel.id)
    rooms                = channel.inventory_handler.retrieve_by_room_type_channel_mapping(
      property,
      room_type_channel_mapping,
      date_start,
      date_end)

    debugger
    expect(rooms).not_to be_empty
  end
end