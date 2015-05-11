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
end