require "rails_helper"

describe "Agoda booking handler spec", :type => :model do
  scenario "Get all Bookings" do
    property = properties(:deluxe)
    connector = AgodaConnector.new(property)
    bookings = connector.get_bookings(365)
    puts bookings.inspect
    expect(bookings).not_to be_empty
  end
end