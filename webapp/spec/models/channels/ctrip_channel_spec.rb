require "rails_helper"

describe CtripChannel, :type => :model do
  before(:each) do
    @channel = CtripChannel.first
  end

  scenario 'fetching room types' do
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

  scenario 'updating rates' do
    it 'updates successfully' do
      rate_alternatives = [100, 200]
      room_types = @channel.room_types_fetcher.retrieve(properties(:big_hotel_1), false, '2015-02-23', '2015-02-15')
      rate_before = #get from ctrip
      if rate_before == rate_alternatives[0]
        @channel.rate_handler.update(rate_alternatives[1])
        rate_after = #get from ota
        expect(rate_after).to eq rate_alternatives[1]
      else
        @channel.rate_handler.update(rate_alternatives[0])
        rate_after = #get from ota
        expect(rate_after).to eq rate_alternatives[0]
      end
    end
  end

  scenario 'updating availabilities' do
    it 'updates successfully' do

      begin

      rescue Exception => e
      end
    end
    it 'fails to update' do
    end
  end
end