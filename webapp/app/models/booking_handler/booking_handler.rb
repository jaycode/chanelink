require 'singleton'

# class to retrieve and store booking from OTA
class BookingHandler
  include Singleton

  # days: How many days in the past?
  def get_bookings(property, days)
    bookings = Array.new
    get_bookings_xml(property, days) do |xml_doc|
      bookings = parse_booking_details_and_store(xml_doc, property)
    end
    bookings
  end

  def get_bookings_xml(property, days)
    # To be overriden by sub class
  end

  def parse_booking_details_and_store(xml_doc, property)
    # To be overridden by sub class
  end

  def retrieve_and_process(property)
    # do nothing, to be overridden by sub class
  end

  def retrieve_and_process_by_bookings_data(bookings_data, property)
  	# do nothing, to be overridden by sub class
  end

  def cancel_booking(booking)
    booking.status = Booking::STATUS_CANCEL
    if booking.save
      update_params = {}
      inventory = Inventory.first(
        :conditions => {
          :property_id => booking.property_id,
          :pool_id => booking.pool_id,
          :room_type_id => booking.room_type_id
        }
      )
      unless inventory.blank?
        # Todo: Make this one loop, too tired to think now.
        dates = []
        booking.date_start.to_date.upto(booking.date_end.to_date) do |date|
          dates << date
        end
        dates.pop
        dates.each do |date|
          if update_params[booking.room_type_id.to_s].blank?
            update_params[booking.room_type_id.to_s] = {}
          end
          update_params[booking.room_type_id.to_s][date.to_s] = "+#{booking.total_rooms}"
        end

        change_set = InventoryChangeSet.update_inventories(booking.property, booking.pool_id, update_params)
        property_channels = PropertyChannel.find_all_by_pool_id(booking.pool_id)

        # Go through each channel inventory handler and ask them to create push xml job
        # except for Ctrip channel.
        property_channels.each do |pc|
          channel = pc.channel
          if channel != booking.channel
            channel.inventory_handler.create_job(change_set) unless pc.disabled?
          end
        end
      end
    end
  end
end
