require "rails_helper"
require "models/channels/agoda/agoda_spec_helper"

describe "Agoda get room types spec", :type => :model do
  include AgodaConnector
  before(:each) do
    @channel    = AgodaChannel.first
    @pool       = pools(:default_big_hotel_1)
    @property   = properties(:big_hotel_1)
    @room_type  = room_types(:superior)
  end

  it 'gets room types successfully' do
    room_types = @channel.room_type_fetcher.retrieve(properties(:big_hotel_1))
    puts '============'
    puts YAML::dump(room_types)
    puts '============'
    # ============
    # ---
    # - !ruby/object:AgodaRoomTypeXml
    #   id: '461004'
    #   name: Deluxe
    # - !ruby/object:AgodaRoomTypeXml
    #   id: '863881'
    #   name: Room B - Double Executive
    # - !ruby/object:AgodaRoomTypeXml
    #   id: '461003'
    #   name: Standard
    # ============
    expect(room_types.count).to be > 0
  end
end