require "rails_helper"
require "connectors/connector"
require "connectors/ctrip_connector"

describe "Ctrip get inventory spec", :type => :model do
  before(:each) do
    @channelClass = CtripChannel
    @connectorClass = CtripConnector
  end
  scenario 'xml test' do
    date_start = Date.today + 1.weeks
    date_end = Date.today + 2.weeks

    property = properties(:big_hotel_1)
    room_type = room_types(:superior)
    rate_type = rate_types(:default)

    @channelClass.first.inventory_handler.get_inventories_xml(property, room_type, date_start, date_end, rate_type) do |xml_doc|
      xml_doc.to_xml(:indent => 3)
      expect(xml_doc).not_to be_nil
    end
  end

  scenario 'inventory retrieval spec' do
    date_start = Date.today + 1.weeks
    date_end = Date.today + 2.weeks

    property = properties(:big_hotel_1)
    room_type = room_types(:superior)
    rate_type = rate_types(:default)

    connector = @connectorClass.new(property)
    inventories = connector.get_inventories(room_type, date_start, date_end, rate_type)
    puts '============='
    puts inventories.inspect
    puts '============='
    expect(inventories).not_to be_nil
  end

  scenario 'Do different rate types with same room type have different inventories (i.e. number of rooms)?' do
    date_start = Date.today + 1.weeks
    date_end = Date.today + 2.weeks

    property = properties(:big_hotel_1)
    room_type = room_types(:superior)
    rate_type1 = rate_types(:default)
    rate_type2 = rate_types(:pay_at_hotel)

    connector = @connectorClass.new(property)
    inventories1 = connector.get_inventories(room_type, date_start, date_end, rate_type1)
    inventories2 = connector.get_inventories(room_type, date_start, date_end, rate_type2)

    similar = true
    inventories1.each_with_index do |inventory, id|
      if inventories2[id].nil?
        similar = false
        break
      end
      if inventories2[id].total_rooms != inventory.total_rooms
        similar = false
      end
    end
    if inventories1.count == inventories2.count and similar
      puts "For #{@channelClass.first.cname}, different rate types with same room type have same inventories."
    else
      puts "For #{@channelClass.first.cname}, each room have different room and rate types."
    end
  end
end