# useful constant for User Interface
class Constant

  MAXIMUM_DAYS_AHEAD = 400
  MAXIMUM_DAYS_AHEAD_GTA_TRAVEL = 31
  GRID_DATE_FORMAT = '%Y-%m-%d'

  ON = 'on'
  OFF = 'off'

  ALL = 'all'

  PERIOD_7DAYS = '7days'
  PERIOD_14DAYS = '14days'
  PERIOD_30DAYS = '30days'

  PERIOD_LIST = {PERIOD_7DAYS => 7, PERIOD_14DAYS => 14, PERIOD_30DAYS => 30}

  YIELD_CREATED = 'created'
  YIELD_CHECKIN = 'checkin'

  TRENDS_DAY = 'day'
  TRENDS_MONTH = 'month'
  
  TRENDS_TOTAL_EARNINGS = 'total_earnings'
  TRENDS_AVG_EARNINGS = 'avg_earnings'
  TRENDS_RESERVATION_COUNT = 'reservation_count'
  TRENDS_TOTAL_ROOM_TYPE = 'total_room_type'

  TRENDS_ALL_TYPES = [TRENDS_TOTAL_EARNINGS, TRENDS_AVG_EARNINGS, TRENDS_RESERVATION_COUNT, TRENDS_TOTAL_ROOM_TYPE]

  POOL_ZERO_INVENTORY = 'zero_inventory'
  POOL_DISABLE_CHANNELS = 'disable_channels'

  ENABLED = 'enabled'
  DISABLED = 'disabled'

  RTCM_RACK_RATE = 'rack_rate'
  RTCM_MASTER_RATE = 'master_rate'
  RTCM_NEW_RATE = 'new_rate'

  # SUPPORT_CTA = [AgodaChannel.first, BookingcomChannel.first, ExpediaChannel.first, OrbitzChannel.first]
  SUPPORT_CTA = [AgodaChannel.first, BookingcomChannel.first, ExpediaChannel.first]
  SUPPORT_GTA_TRAVEL_CHANNEL_CTA = [GtaTravelChannel.first]
  # SUPPORT_CTD = [AgodaChannel.first, BookingcomChannel.first, ExpediaChannel.first, OrbitzChannel.first]
  SUPPORT_CTD = [AgodaChannel.first, BookingcomChannel.first, ExpediaChannel.first]
  SUPPORT_GTA_TRAVEL_CHANNEL_CTB = [GtaTravelChannel.first]

  REPORT_MAX_COL = 18

  XMLNS_XSI_2001 = 'http://www.w3.org/2001/XMLSchema-instance'

  # get the 400th day from now
  def self.maximum_end_date
    ahead = MAXIMUM_DAYS_AHEAD
    DateTime.now.beginning_of_day + ahead.days
  end

  # used by check in report form
  def self.check_in_periods
    result = Array.new
    result << [I18n.t("reports.checkin.periods.#{PERIOD_7DAYS}"), PERIOD_7DAYS]
    result << [I18n.t("reports.checkin.periods.#{PERIOD_14DAYS}"), PERIOD_14DAYS]
    result << [I18n.t("reports.checkin.periods.#{PERIOD_30DAYS}"), PERIOD_30DAYS]
    result
  end

  # used by trend report form
  def self.trends_type
    result = Array.new
    result << [I18n.t("reports.channel_trends.report_type.placeholder"), '']
    result << [I18n.t("reports.channel_trends.report_type.#{TRENDS_TOTAL_EARNINGS}"), TRENDS_TOTAL_EARNINGS]
    result << [I18n.t("reports.channel_trends.report_type.#{TRENDS_AVG_EARNINGS}"), TRENDS_AVG_EARNINGS]
    result << [I18n.t("reports.channel_trends.report_type.#{TRENDS_RESERVATION_COUNT}"), TRENDS_RESERVATION_COUNT]
    result << [I18n.t("reports.channel_trends.report_type.#{TRENDS_TOTAL_ROOM_TYPE}"), TRENDS_TOTAL_ROOM_TYPE]
    result
  end

end
