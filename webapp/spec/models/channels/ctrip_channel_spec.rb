require "rails_helper"

describe CtripChannel, :type => :model do
  before(:each) do
    @channel = CtripChannel.first

    # Room rate plan id from OTA mapped to our room to test in this code.
    @rate_plan_id_to_test = room_type_channel_mappings(:superior_ctrip_room_a).settings(:ctrip_room_rate_plan_code)
  end

  describe 'fetching room types' do
    it 'fetched successfully' do
      begin
        room_types = @channel.room_type_fetcher.retrieve(properties(:big_hotel_1), false, '2015-02-23', '2015-02-25')
      rescue Exception => e
        puts "Error: #{e.message}"
      end
      expect(room_types.count).to be > 0
    end
    it 'fails to fetch' do
      error = 0
      begin
        room_types = @channel.room_type_fetcher.retrieve(properties(:big_hotel_2))
      rescue Exception => e
        error = 1
        # puts "Error: #{e.message}"
      end
      expect(error).to eq 1
    end
  end

  describe 'updating rates' do
    before(:each) do
      @pool = pools(:default_big_hotel_1)
      @property = properties(:big_hotel_1)
    end

    it 'updates successfully' do
      date_start = '2015-02-23'
      date_end = '2015-02-25'
      rates_before = get_rates
      rate_alternatives = [100, 200]
      change_set = MasterRateChangeSet.create
      if rates_before[1] == rate_alternatives[0]
        update_rates(rate_alternatives[1], date_start, date_end)
        rates_after = get_rates(date_start, date_end)
        rates_after.each do |rate|
          expect(rate).to eq rate_alternatives[1]
        end
      else
        update_rates(rate_alternatives[0], date_start, date_end)
        rates_after = get_rates(date_start, date_end)
        rates_after.each do |rate|
          expect(rate).to eq rate_alternatives[0]
        end
      end
    end

    def get_rates(date_start, date_end)
      rates = Array.new
      room_types = @channel.room_type_fetcher.retrieve_xml(properties(:big_hotel_1), false, date_start, date_end) do |xml_doc|
        ctrip_room_types        = xml_doc.xpath('//RatePlan')
        ctrip_room_types.each do |rt|
          if rt['RatePlanCode'] == @rate_plan_id_to_test
            ctrip_room_type_rates = rt.xpath('Rates/Rate')
            puts ctrip_room_type_rates.inspect
            ctrip_room_type_rates.each do |rate|
              temp_base_by_guest_amts = Array.new
              base_by_guest_amts      = rate.xpath('BaseByGuestAmts/BaseByGuestAmt')

              if base_by_guest_amts.count > 0
                base_by_guest_amts.each do |base_by_guest_amt|
                  rates << base_by_guest_amt['AmountAfterTax']
                end
              end
            end
          end
        end
      end
      rates
    end

    def update_rates(amount, date_start, date_end)
      date_start = Date.new(date_start)
      date_end = Date.new(date_end)

      # ChangeSet is like the wrapper of a set of changes.
      change_set = MasterRateChangeSet.create

      # This is similar with master_rates_controller's handle_amount.
      date_start..date_end do |date|
        existing_rate = MasterRate.find_by_date_and_property_id_and_pool_id_and_room_type_id(
          date, @property.id, params[:pool_id], rt.id)

        # no existing, create new master rate object
        if existing_rate.blank?
          if amount.blank? or amount == 0
            # do nothing
          elsif amount.to_f > 0
            rate = MasterRate.new
            rate.date = date
            rate.amount = amount
            rate.room_type_id = rt.id
            rate.property = @property
            rate.pool_id = @pool.id

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
      @channel.master_rate_handler.create_job(change_set)

      # But we don't want to use delayed jobs, so...
      @channel.master_rate_handler.

    end

    # create log/version for each master rate changes
    def create_master_rate_log(master_rate)
      MasterRateLog.create(:master_rate_id => master_rate.id, :amount => master_rate.amount)
    end
  end

  describe 'updating inventory availabilities' do
    it 'updates successfully' do

    end
    it 'fails to update' do
    end
    def update_inventories(new_rate, date_start, date_end)
      # Code from inventories_controller
      logs = Array.new
      pool = Pool.find(params[:pool_id])

      date_start..date_end do |date|
        inventory = Inventory.new
        inventory.date = date
        inventory.total_rooms = date_inv[1]
        inventory.room_type_id = rt.id
        inventory.property = current_property
        inventory.pool_id = params[:pool_id]
      end

      change_set = InventoryChangeSet.create
      logs.each do |log|
        log.update_attribute(:change_set_id, change_set.id)
      end

      # determine xml channel job that want to be created
      property_channels = PropertyChannel.find_all_by_pool_id(pool.id)

      # go through each channel inventory handler and ask them to create push xml job
      property_channels.each do |pc|
        channel = pc.channel
        channel.inventory_handler.create_job(change_set) unless pc.disabled?
      end
    end
  end
end