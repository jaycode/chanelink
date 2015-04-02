module ReportsHelper

  include ActiveSupport

  # organize bookings by dates
  def checkin_organize_bookings_by_dates(bookings)
    by_dates = OrderedHash.new
    sorted_by_date_start = bookings.sort_by {|b| b.date_start}
    sorted_by_date_start.each do |booking|
      key = booking.date_start
      if by_dates.has_key?(key)
        by_dates[key] << booking
      else
        arr = Array.new
        arr << booking
        by_dates[key] = arr
      end
    end
    by_dates
  end

  # date picker for report form
  def report_date_picker_js(field_id)
    parameter = {
      :dateFormat => "yy-mm-dd"
    }
    javascript_tag "$(function() {
        $( \"\##{field_id}\" ).datepicker(#{parameter.to_json});
      });"
  end

  # take out bookings category
  def trends_extract_category(bookings)
    "['#{bookings.first[1].keys.join("', '")}']"
  end

  def trends_extract_category_count(bookings)
    bookings.first[1].keys.size
  end
  
  def trends_extract_channel(bookings)
    "['#{bookings.keys.join("', '")}']"
  end

  def trends_extract_room_type_id(bookings)
    (bookings.map &:room_type_id).uniq
  end

  def trends_extract_total_earnings(data)
    total_earnings = Array.new
    data.keys.each do |date|
     total_earnings << calculate_total_earnings(data[date])
    end
    "[#{total_earnings.join(', ')}]"
  end

  def calculate_total_earnings(bookings)
    result = 0
    if !bookings.blank?
      bookings.each do |booking|
        result = result + booking.amount
      end
    end
    result
  end

  def trends_extract_avg_earnings(data)
    avg_earnings = Array.new
    data.keys.each do |date|
      avg_earnings << calculate_avg_earnings(data[date])
    end
    "[#{avg_earnings.join(', ')}]"
  end

  def calculate_avg_earnings(bookings)
    result = 0
    if !bookings.blank?
      total = 0
      bookings.each do |booking|
        total = total + booking.amount
      end
      result = (total * 1.0) / bookings.size
    end
    result
  end

  def trends_extract_reservation_count(data)
    reservation_count = Array.new
    data.keys.each do |date|
      reservation_count << calculate_reservation_count(data[date])
    end
    "[#{reservation_count.join(', ')}]"
  end

  def calculate_reservation_count(bookings)
    result = 0
    if !bookings.blank?
      result = bookings.size
    end
    result
  end

  def trends_extract_room_type_count(data, room_type_id)
    collected = Array.new
    categories = data.first[1].keys
    channels = data.keys
    categories.each do |category|
      channels.each do |channel|
        bookings = data[channel][category]
        collected << (bookings.select {|b| b.room_type_id == room_type_id}).count
      end
    end
    "[#{collected.join(', ')}]"
  end
  
end
