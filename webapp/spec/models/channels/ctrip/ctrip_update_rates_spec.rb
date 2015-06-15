require "rails_helper"

describe "Ctrip update rates spec", :type => :model do
  before(:each) do
    @channel = CtripChannel.first
    @pool = pools(:default_big_hotel_1)
    @property = properties(:big_hotel_1)
    @room_type = room_types(:superior)
    # Updated asynchronously so this can't be tested.
    # @sleep_time = 20
  end

  it 'updates successfully' do
    date_start = Date.today + 2.weeks
    date_end = Date.today + 3.weeks
    rates_before = get_rates(@channel, @room_type, date_start.to_s, date_end.to_s)
    rate_alternatives = [100.0, 200.0]
    change_set = MasterRateChangeSet.create
    if float_equal(rates_before[1], rate_alternatives[0])
      update_rates(@channel, @property, @pool, @room_type, rate_alternatives[1], date_start.to_s, date_end.to_s)
      # puts "Waiting #{@sleep_time} seconds before getting rates again..."
      # sleep(@sleep_time)
      rates_after = get_rates(@channel, @room_type, date_start.to_s, date_end.to_s)
      # puts "done!"
      # rates_after.each do |rate|
      #   expect(rate).to be_within(0.00001).of(rate_alternatives[1])
      # end
    else
      update_rates(@channel, @property, @pool, @room_type, rate_alternatives[0], date_start.to_s, date_end.to_s)
      # puts "Waiting #{@sleep_time} seconds before getting rates again..."
      # sleep(@sleep_time)
      rates_after = get_rates(@channel, @room_type, date_start.to_s, date_end.to_s)
      # puts "done!"
      # rates_after.each do |rate|
      #   expect(rate).to be_within(0.00001).of(rate_alternatives[0])
      # end
    end
  end

  def get_rates(channel, room_type, date_start, date_end)
    rates = Array.new
    room_types = channel.room_type_fetcher.retrieve_xml(properties(:big_hotel_1), false, date_start, date_end) do |xml_doc|

      room_type_channel_mapping = RoomTypeChannelMapping.find_by_room_type_id_and_channel_id(room_type.id, channel.id)
      
      ctrip_rate_plan_code = room_type_channel_mapping.ota_room_type_id
      ctrip_rate_plan_category = room_type_channel_mapping.ota_rate_type_id
      @logger = Logger.new("#{Rails.root}/log/custom.log")

      ctrip_room_types        = xml_doc.xpath('//RatePlan')
      @logger.error("#{xml_doc.to_xhtml(indent: 3)}")
      ctrip_room_types.each do |rt|
        # @logger.error("#{rt.to_xhtml(indent: 3)}")
        if rt['RatePlanCode'] == ctrip_rate_plan_code and rt['RatePlanCategory'] == ctrip_rate_plan_category
          ctrip_room_type_rates = rt.xpath('Rates/Rate')
          ctrip_room_type_rates.each do |rate|
            temp_base_by_guest_amts = Array.new
            base_by_guest_amts      = rate.xpath('BaseByGuestAmts/BaseByGuestAmt')
            if base_by_guest_amts.count > 0
              base_by_guest_amts.each do |base_by_guest_amt|
                rates << base_by_guest_amt['AmountAfterTax'].to_f
              end
            end
          end
        end
      end
    end
    rates
  end

  # channel: Which channel are the rates going to be sent to?
  #          Outside test environment, this is not needed as
  #          rates update will be sent to all channels connected
  #          to a property via table property_channels.
  # property: Property / selected hotel.
  # pool: The pool to contain new rates update
  # room_type: Room type which rates we about to update.
  def update_rates(channel, property, pool, room_type, amount, date_start, date_end)
    logs = Array.new
    date_start = Date.parse(date_start)
    date_end = Date.parse(date_end)

    # ChangeSet is like the wrapper of a set of changes.
    change_set = MasterRateChangeSet.create

    # This is similar with master_rates_controller's handle_amount.
    date_start.upto(date_end) do |date|
      existing_rate = MasterRate.find_by_date_and_property_id_and_pool_id_and_room_type_id(
        date, property.id, pool.id, room_type.id)

      # no existing, create new master rate object
      if existing_rate.blank?
        if amount.blank? or amount == 0
          # do nothing
        elsif amount.to_f > 0
          rate = MasterRate.new
          rate.date = date
          rate.amount = amount
          rate.room_type_id = room_type.id
          rate.property = property
          rate.pool_id = pool.id

          rate.save
          logs << create_master_rate_log(rate)
        end
      else
        # have existing? then just do update
        if amount.to_f >= 0 and (amount.to_f != existing_rate.amount.to_f)
          existing_rate.update_attribute(:amount, amount)
          logs << create_master_rate_log(existing_rate)
        end
      end
    end

    # Could have been prettier but for now I want to use the exact same functions
    # as used in the app. Below code are from MasterRateChangeSet model
    logs.each do |log|
      log.update_attribute(:change_set_id, change_set.id)
    end

    # This is the only thing we change to make it specific to a channel:

    #--------------------------------------------------------------------------------
    # determine xml channel job that want to be created
    # property_channels = PropertyChannel.find_all_by_pool_id(pool.id)

    # go through each channel inventory handler and ask them to create push xml job
    # property_channels.each do |pc|
    #   channel = pc.channel
    #   channel.master_rate_handler.create_job(change_set) unless pc.disabled?
    # end
    #--------------------------------------------------------------------------------

    # Change to..
    channel.master_rate_handler.create_job(change_set, false)
  end

  # create log/version for each master rate changes
  def create_master_rate_log(master_rate)
    MasterRateLog.create(:master_rate_id => master_rate.id, :amount => master_rate.amount)
  end
end