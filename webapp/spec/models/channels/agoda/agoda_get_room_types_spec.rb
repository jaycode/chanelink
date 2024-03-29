require 'rails_helper'
require 'connectors/connector'
require 'connectors/agoda_connector'

describe "Agoda get room types spec", :type => :model do
  before(:each) do
    @channel    = AgodaChannel.first
    @pool       = pools(:default_big_hotel_1)
    @property   = properties(:big_hotel_1)
    @room_type  = room_types(:superior)
  end

  it 'builds request correctly' do
    request = AgodaChannel.first.room_type_fetcher.request(@property)
    puts 'REQUEST'
    puts '============'
    puts request.to_xml
    expect(request.to_xml).not_to be_empty
    puts '============'
  end

  it 'gets xml successfully' do
    AgodaChannel.first.room_type_fetcher.retrieve_xml(@property) do |xml_doc|
      puts 'RESPONSE'
      puts '============'
      puts xml_doc.to_xml
      expect(xml_doc.to_xml).not_to be_empty
      puts '============'
    end
  end

  # This is used in room type channel mapping page
  it 'mapped rooms excluded successfully' do
    connector = AgodaConnector.new(@property)
    all_room_types = connector.get_room_types(false)
    room_types = connector.get_room_types(true)
    expect(room_types.count).to eq(all_room_types.count - 2)
    puts '============'
    puts YAML::dump(room_types)
    puts '============'
    expect(room_types.count).to be > 0
    mapped_room_exists = false
    room_types.each do |room_type|
      mapping = RoomTypeChannelMapping.all(
        :conditions => {
          :ota_room_type_id => room_type.id,
          :ota_rate_type_id => room_type.rate_type_id,
          :channel_id => channels(:agoda).id
        }
      )
      unless mapping.empty?
        mapped_room_exists = true
      end
    end
    expect(mapped_room_exists).to eq(false)
  end

  # This demonstrates the procedure to get unmapped rooms
  # in views/properties/edit.html.erb.
  scenario "Showing only chanelink's unmapped rooms." do
    rooms = Array.new
    mapped_rooms = Array.new
    property = properties(:big_hotel_1)
    channel_rooms = AgodaConnector.new(property).get_room_types(false).count
    channel_ex_mapped_rooms = AgodaConnector.new(property).get_room_types(true).count
    property.room_types.each do |rt|
      mapping = RoomTypeChannelMapping.first(
        :conditions => ['room_type_id = ? AND ota_room_type_id IS NOT NULL',
                        rt.id]
      )
      if mapping.blank?
        rooms << "#{rt.name}"
      else
        mapped_rooms << "#{rt.name}"
      end
    end
    puts "rooms: #{rooms.inspect}"
    puts "mapped_rooms: #{mapped_rooms.inspect}"
    puts "total mapped rooms: #{mapped_rooms.count}"
    puts "total channel rooms: #{channel_rooms}"
    puts "mapped channel rooms: #{channel_rooms - channel_ex_mapped_rooms}"
    expect(mapped_rooms.count).to eq(channel_rooms - channel_ex_mapped_rooms)
  end
end