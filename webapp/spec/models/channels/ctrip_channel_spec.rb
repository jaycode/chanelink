require "rails_helper"
describe CtripChannel, :type => :model do
  scenario 'fetching room types' do
    channel = CtripChannel.first
    room_types = channel.room_type_fetcher.retrieve(properties(:big_hotel_1))
    puts "room types: #{room_types.inspect}"
    expect(room_types.count).to be > 0
  end
end