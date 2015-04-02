# controller for report module
class ReportsController < ApplicationController

  include ActiveSupport

  before_filter :member_authenticate_and_property_selected

  DAY_FORMAT = '%d/%m/%y'
  MONTH_FORMAT = '%m/%y'

  # check in report
  def checkin

    # set query scope to current property and the sorting
    scope = Booking.scoped({})
    scope = scope.where(:property_id => current_property.id)
    scope = scope.order('booking_date ASC')

    # handle period
    period = Constant::PERIOD_LIST[Constant::PERIOD_7DAYS]
    if params[:period] and Constant::PERIOD_LIST.keys.include?(params[:period])
      period = Constant::PERIOD_LIST[params[:period]]
    end
    today = DateTime.now.beginning_of_day
    scope = scope.date_start_between(today, today + period.days)

    # handle pool
    if current_property.single_pool?
      scope = scope.where(:pool_id => current_property.pools.first.id)
    elsif params[:pool] and !current_property.pools.find_by_id(params[:pool]).blank?
      scope = scope.where(:pool_id => params[:pool])
    end

    @bookings = scope
  end

  # channel yield report
  def channel_yield
    @errors = Array.new
    date_from = nil
    date_to = nil
    @bookings = nil
    @parameter_exist = (params[:date_type] or params[:date_from] or params[:date_to] or params[:pool])? true : false

    # validate parameter given
    if @parameter_exist
      if params[:date_type] != Constant::YIELD_CREATED and params[:date_type] != Constant::YIELD_CHECKIN
        @errors << t('reports.channel_yield.message.date_type_not_exist')
      end

      if params[:date_from] and params[:date_from].blank?
        @errors << t('reports.channel_yield.message.date_from_not_exist')
      end

      if params[:date_to] and params[:date_to].blank?
        @errors << t('reports.channel_yield.message.date_to_not_exist')
      end

      # date_from must be before date_to
      if !params[:date_from].blank? and !params[:date_to].blank?
        date_from = Date.strptime(params[:date_from])
        date_to = Date.strptime(params[:date_to])

        if date_from > date_to
          @errors << t('reports.channel_yield.message.date_from_must_be_earlier')
        end
      end

      if !@errors.blank?
        flash.now[:alert] = @errors
      else
        # if no errors then render report
        scope = Booking.scoped({})
        scope = scope.where(:property_id => current_property.id)

        # handle data type
        if params[:date_type] == Constant::YIELD_CREATED
          scope = scope.booking_date_between(date_from.beginning_of_day, date_to.end_of_day)
        elsif params[:date_type] == Constant::YIELD_CHECKIN
          scope = scope.date_start_between(date_from.beginning_of_day, date_to.end_of_day)
        end

        # handle pool
        if current_property.single_pool?
          scope = scope.where(:pool_id => current_property.pools.first.id)
        elsif params[:pool] and !current_property.pools.find_by_id(params[:pool]).blank?
          scope = scope.where(:pool_id => params[:pool])
        end

        @bookings = scope

        # if csv option specified then generate csv
        if !@bookings.blank? and params[:csv]
          generate_channel_yield_in_csv
        end
      end
    end
  end

  # render channel trend report
  def channel_trends
    @errors = Array.new
    @bookings = nil
    @report_type = nil
    @parameter_exist = (params[:date_type] or params[:date_from] or params[:date_to] or params[:breakdown] or params[:pool] or params[:report_type])? true : false
    @breakdown = nil
    @pool = params[:pool]
    @channel = params[:channel]
    @date_type = params[:date_type]

    # validate parameter given
    if @parameter_exist
      if params[:date_type] != Constant::YIELD_CREATED and params[:date_type] != Constant::YIELD_CHECKIN
        @errors << t('reports.channel_trends.message.date_type_not_exist')
      end

      if params[:date_from] and params[:date_from].blank?
        @errors << t('reports.channel_trends.message.date_from_not_exist')
      end

      if params[:date_to] and params[:date_to].blank?
        @errors << t('reports.channel_trends.message.date_to_not_exist')
      end

      if params[:breakdown] != Constant::TRENDS_DAY and params[:breakdown] != Constant::TRENDS_MONTH
        @errors << t('reports.channel_trends.message.breakdown_not_exist')
      else
        @breakdown = params[:breakdown]
      end

      if !Constant::TRENDS_ALL_TYPES.include?(params[:report_type])
        @errors << t('reports.channel_trends.message.report_type_not_exist')
      else
        @report_type = params[:report_type]
      end

      # date_from must be earlier than date_to
      if !params[:date_from].blank? and !params[:date_to].blank?
        @date_from = Date.strptime(params[:date_from])
        @date_to = Date.strptime(params[:date_to])

        if @date_from > @date_to
          @errors << t('reports.channel_trends.message.date_from_must_be_earlier')
        end
      end

      if !@errors.blank?
        flash.now[:alert] = @errors
      else
        # if no errors then render the report
        scope = Booking.scoped({})
        scope = scope.where(:property_id => current_property.id)

        # handle date type
        if params[:date_type] == Constant::YIELD_CREATED
          scope = scope.booking_date_between(@date_from.beginning_of_day, @date_to.end_of_day)
        elsif params[:date_type] == Constant::YIELD_CHECKIN
          scope = scope.date_start_between(@date_from.beginning_of_day, @date_to.end_of_day)
        end

        # handle pool
        if current_property.single_pool?
          scope = scope.where(:pool_id => current_property.pools.first.id)
        elsif params[:pool] and !current_property.pools.find_by_id(params[:pool]).blank?
          scope = scope.where(:pool_id => params[:pool])
        end

        # handle channel
        if params[:channel] and !current_property.channels.find_by_channel_id(params[:channel]).blank?
          scope = scope.where(:channel_id => params[:channel])
        end

        @bookings = scope
        @filtered_bookings = trends_organize_bookings_by_channels_and_breakdown
        puts "booking size #{@bookings.size}"
        @bookings.each do |b|
          puts b.id
        end

        # if csv specified then generate in csv
        if params[:csv]
          if @report_type == 'total_earnings'
            generate_channel_trends_earnings_in_csv
          elsif @report_type == 'avg_earnings'
            generate_channel_trends_avg_earnings_in_csv
          elsif @report_type == 'reservation_count'
            generate_channel_trends_reservation_count_in_csv
          elsif @report_type == 'total_room_type'
            generate_channel_trends_total_room_type_in_csv
          end
        end
      end
    end
  end

  private

  helper_method :organize_bookings_by_channels

  # given a list of bookings, return in hash bookings grouped by channels
  def organize_bookings_by_channels(bookings)
    by_channels = OrderedHash.new
    if !bookings.blank?
      sorted_by_channel_id = bookings.sort_by {|b| b.channel_id}
      sorted_by_channel_id.each do |booking|
        key = booking.channel_id
        if by_channels.has_key?(key)
          by_channels[key] << booking
        else
          # register new channel to the hash
          arr = Array.new
          arr << booking
          by_channels[key] = arr
        end
      end
    end
    by_channels
  end

  # given a list of bookings, return in hash bookings grouped by channels and date breakdown
  def trends_organize_bookings_by_channels_and_breakdown
    result = init_channel_breakdown_key

    @bookings.each do |booking|
      date_to_use = @date_type == Constant::YIELD_CREATED ? booking.booking_date : booking.date_start
      channel = booking.channel.name
      breakdown = @breakdown == Constant::TRENDS_DAY ? date_to_use.strftime(DAY_FORMAT) : date_to_use.strftime(MONTH_FORMAT)
      result[channel][breakdown] << booking
    end
    result
  end

  # return a hash where key already grouped by channel, then date breakdown
  def init_channel_breakdown_key
    result = OrderedHash.new

    channel_list = Array.new
    if !@channel.blank? and !current_property.channels.find_by_channel_id(@channel).blank?
      channel_list << Channel.find(@channel).name
    else
      if !@pool.blank?
        PropertyChannel.order('channel_id ASC').find_all_by_pool_id(@pool).each do |pc|
          channel_list << pc.channel.name
        end
      else
        PropertyChannel.order('channel_id ASC').find_all_by_property_id(current_property.id).each do |pc|
          channel_list << pc.channel.name
        end
      end
    end

    # initialize breakdown date
    breakdown_list = Array.new
    # by day
    if @breakdown == Constant::TRENDS_DAY
      loop_start = @date_from.beginning_of_day
      loop_to = @date_to.end_of_day

      while loop_start <= loop_to
        breakdown_list << loop_start.strftime(DAY_FORMAT)
        loop_start = loop_start + 1.day
      end
    else
      # by month
      loop_start = @date_from.beginning_of_month
      loop_to = @date_to.end_of_month

      while loop_start <= loop_to
        breakdown_list << loop_start.strftime(MONTH_FORMAT)
        loop_start = (loop_start + 1.month).beginning_of_month
      end
    end

    # combine channel and date breakdown
    channel_list.each do |ch|
      result[ch] = OrderedHash.new
      breakdown_list.each do |br|
        result[ch][br] = Array.new
      end
    end

    result
  end

  # given list of bookings, calculate total bookings value
  def calculate_total_earnings(bookings)
    result = 0
    if !bookings.blank?
      bookings.each do |booking|
        result = result + booking.amount_in_base_currency
      end
    end
    result
  end

  # given bookings, calculate earnings by channel for csv
  def generate_channel_trends_earnings_in_csv
    channels = @filtered_bookings.keys
    dates = @filtered_bookings.first[1].keys
    heading = [''] + channels
    csv_string = FasterCSV.generate do |csv|
      # csv header
      csv << heading
      dates.each do |date|
        row = Array.new
        row << date
        # by channel
        channels.each do |channel|
          row << calculate_total_earnings(@filtered_bookings[channel][date])
        end
        csv << row
      end
    end

    send_data csv_string,
            :type => 'text/csv; charset=iso-8859-1; header=present',
            :disposition => "attachment; filename=channel_trends_earnings.csv"
  end

  # given bookings, calculate average earnings
  def calculate_avg_earnings(bookings)
    result = 0
    if !bookings.blank?
      total = 0
      bookings.each do |booking|
        total = total + booking.amount_in_base_currency
      end
      result = (total * 1.0) / bookings.size
    end
    result
  end

  # given bookings, calculate avg earnings by channel for csv
  def generate_channel_trends_avg_earnings_in_csv
    channels = @filtered_bookings.keys
    dates = @filtered_bookings.first[1].keys
    heading = [''] + channels
    csv_string = FasterCSV.generate do |csv|
      # date for csv header
      csv << heading
      dates.each do |date|
        row = Array.new
        row << date
        # by channel
        channels.each do |channel|
          row << calculate_avg_earnings(@filtered_bookings[channel][date])
        end
        csv << row
      end
    end

    send_data csv_string,
            :type => 'text/csv; charset=iso-8859-1; header=present',
            :disposition => "attachment; filename=channel_trends_avg_earnings.csv"
  end

  # given bookings, return total bookings
  def calculate_reservation_count(bookings)
    result = 0
    if !bookings.blank?
      result = bookings.size
    end
    result
  end

 # given bookings, return total bookings by channel and dates
  def generate_channel_trends_reservation_count_in_csv
    channels = @filtered_bookings.keys
    dates = @filtered_bookings.first[1].keys
    heading = [''] + channels
    csv_string = FasterCSV.generate do |csv|
      csv << heading
      dates.each do |date|
        row = Array.new
        row << date
        channels.each do |channel|
          row << calculate_reservation_count(@filtered_bookings[channel][date])
        end
        csv << row
      end
    end

    send_data csv_string,
            :type => 'text/csv; charset=iso-8859-1; header=present',
            :disposition => "attachment; filename=channel_trends_reservation_count.csv"
  end

  # calculate total bookings grouped by room type
  def generate_channel_trends_total_room_type_in_csv
    channels = @filtered_bookings.keys
    dates = @filtered_bookings.first[1].keys
    room_type_ids = (@bookings.map &:room_type_id).uniq
    heading = ['']

    # build heading with format channel-roomtype
    channels.each do |channel|
      room_type_ids.each do |room_type_id|
        rt = RoomType.find(room_type_id)
        heading << "#{channel} - #{rt.name}"
      end
    end

    csv_string = FasterCSV.generate do |csv|
      csv << heading
      dates.each do |date|
        row = Array.new
        row << date

        # generate total bookings by channel and room type
        channels.each do |channel|
          room_type_ids.each do |room_type_id|
            rt = RoomType.find(room_type_id)
            bookings = @filtered_bookings[channel][date]
            row << (bookings.select {|b| b.room_type_id == room_type_id}).count
          end
        end

        csv << row
      end
    end

    send_data csv_string,
            :type => 'text/csv; charset=iso-8859-1; header=present',
            :disposition => "attachment; filename=channel_trends_reservation_count.csv"
  end

  # channel yield report in CSV
  def generate_channel_yield_in_csv
    csv_string = FasterCSV.generate do |csv|
      # csv header
      csv << [I18n.t('reports.channel_yield.label.channel'),
          I18n.t('reports.channel_yield.label.reservations'),
          I18n.t('reports.channel_yield.label.lead_time'),
          I18n.t('reports.channel_yield.label.los'),
          I18n.t('reports.channel_yield.label.avg_earnings'),
          I18n.t('reports.channel_yield.label.total_earnings')]


      grand_reservation_total = 0
      grand_total_lead_time = 0
      grand_total_los = 0
      grand_total_amount = 0

      by_channels = organize_bookings_by_channels(@bookings)
      
      # go through bookings by channels
      by_channels.each do |channel_id, array|

        reservation_total = array.count
        total_lead_time = 0
        total_los = 0
        total_amount = 0

        array.each do |booking|
          total_lead_time = total_lead_time + booking.lead_time
          total_los = total_los + booking.length_of_stay
          total_amount = total_amount + booking.amount_in_base_currency
        end
        
        csv << [Channel.find(channel_id).name,
            reservation_total,
            (total_lead_time * 1.0) / reservation_total,
            (total_los * 1.0) / reservation_total,
            (total_amount * 1.0) / reservation_total,
            total_amount]

        grand_reservation_total = grand_reservation_total + reservation_total
        grand_total_lead_time = grand_total_lead_time + total_lead_time
        grand_total_los = grand_total_los + total_los
        grand_total_amount = grand_total_amount + total_amount
      end
      
      csv << [I18n.t('reports.channel_yield.label.total'), grand_reservation_total,
          (grand_total_lead_time * 1.0) / grand_reservation_total,
          (grand_total_los * 1.0) / grand_reservation_total,
          (grand_total_amount * 1.0) / grand_reservation_total,
          grand_total_amount]
    end

    send_data csv_string,
            :type => 'text/csv; charset=iso-8859-1; header=present',
            :disposition => "attachment; filename=channel_yield.csv"
  end
end
