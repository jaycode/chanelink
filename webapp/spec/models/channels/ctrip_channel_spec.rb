require "rails_helper"

describe CtripChannel, :type => :model do
  scenario 'fetching room types - success' do
    channel = CtripChannel.first
    begin
      room_types = channel.room_type_fetcher.retrieve(properties(:big_hotel_1), false, '2015-02-23', '2015-02-25')
    rescue Exception => e
      puts "Error: #{e.message}"
    end
    expect(room_types.count).to be > 0
  end
  scenario 'fetching room types - failed' do
    channel = CtripChannel.first
    error = 0
    begin
      room_types = channel.room_type_fetcher.retrieve(properties(:big_hotel_2))
    rescue Exception => e
      error = 1
      # puts "Error: #{e.message}"
    end
    expect(error).to eq 1
  end

  scenario 'updating availabilities - success' do
  end

  scenario 'updating availabilities - failed' do
  end

end