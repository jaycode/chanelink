require "rails_helper"
require "connectors/connector"
require "connectors/agoda_connector"

describe "Agoda booking handler spec", :type => :model do
  scenario "Get all Bookings then synchronize them" do
    Booking.destroy_all
    BookingRetrieval.destroy_all
    property = properties(:big_hotel_1)
    connector = AgodaConnector.new(property)
    bookings = connector.get_bookings(365)
    expect(bookings).not_to be_empty

    # Now synchronize. This is what happens in BookingsController when sync feature is called.
    # Synchronization is done by subtracting the number of rooms of inventories with confirmed bookings.
    PropertyChannel.active_only.all(:conditions => {:property_id => property.id}).each do |property_channel|

      inventories =
      property_channel.channel.update_inventory
    end

  end
end