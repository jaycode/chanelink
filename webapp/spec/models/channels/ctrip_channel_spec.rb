require "rails_helper"

describe CtripChannel, :type => :model do
  before(:each) do
    @channel = CtripChannel.first

    # Room rate plan id from OTA mapped to our room to test in this code.
    @rate_plan_id_to_test = room_type_channel_mappings(:superior_ctrip_room_a).settings(:ctrip_room_rate_plan_code)
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

  describe 'updating rates' do
    it 'updates successfully' do
      rate_alternatives = [100, 200]
      room_types = @channel.room_type_fetcher.retrieve(properties(:big_hotel_1), false, '2015-02-23', '2015-02-25')
      # room_type = room_types.find {|rt| rt.id == @rate_plan_id_to_test}
      room_types.each do |rt|
        puts "#{rt.id} - #{rt.name} [#{rt.rate_plan_category}]"
        if rt.id == @rate_plan_id_to_test
          room_type = rt
          puts "found!"
        end
      end
      puts room_types[0].rate_plan_category
      rate_before = #get from ctrip

      change_set = MasterRateChangeSet.create
      if rate_before == rate_alternatives[0]
        @channel.master_rate_handler.update(rate_alternatives[1])
        rate_after = #get from ota
        expect(rate_after).to eq rate_alternatives[1]
      else
        @channel.master_rate_handler.update(rate_alternatives[0])
        rate_after = #get from ota
        expect(rate_after).to eq rate_alternatives[0]
      end
    end
  end

  describe 'updating availabilities' do
    it 'updates successfully' do

      begin

      rescue Exception => e
      end
    end
    it 'fails to update' do
    end
  end
end