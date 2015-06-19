# controler to handle inventories data from inventory grid
class InventoriesController < ApplicationController

  before_filter :member_authenticate_and_property_selected
  before_filter :set_pool, :except => :pool_selection

  # renderer for the inventory grid form
  def grid
    handle_date
    @pool = Pool.find(params[:pool_id])
  end

  # handler to receive data from form submission
  def update
    if validate_inventory_date
      do_update
      redirect_to grid_inventories_path(:pool_id => params[:pool_id], :inv_start => params[:inv_start])
    else
      redirect_to grid_inventories_path(:pool_id => params[:pool_id], :inv_start => params[:inv_start]), :flash => {:inventory => params}
    end
  end

  def do_update
    logs = Array.new
    pool = Pool.find(params[:pool_id])

    # go through each value specified and save it to database
    current_property.room_types.each do |rt|
      if params["#{rt.id}"]
        current_property.account.rate_types.each do |rate_type|
          params["#{rt.id}"]["#{rate_type.id}"].each do |date_inv|
            total_rooms = date_inv[1]
            existing_inv = Inventory.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_rate_type_id(
              date_inv[0], current_property.id, params[:pool_id], rt.id, rate_type.id)

            # create new inventory object
            if existing_inv.blank?
              if total_rooms.blank? or total_rooms == 0
                # do nothing
              elsif total_rooms.to_i > 0
                inventory = Inventory.new
                inventory.date = date_inv[0]
                inventory.total_rooms = date_inv[1]
                inventory.room_type_id = rt.id
                inventory.rate_type_id = rate_type.id
                inventory.property = current_property
                inventory.pool_id = params[:pool_id]

                inventory.save

                logs << create_inventory_log(inventory)
              end
            else
              # if existing exist then do update if value is not 0
              if total_rooms.to_i >= 0 and (total_rooms.to_i != existing_inv.total_rooms.to_i)
                existing_inv.update_attribute(:total_rooms, total_rooms)
                logs << create_inventory_log(existing_inv)
              end
            end
          end
        end
      end
    end
    InventoryChangeSet.create_job(logs, pool)

    if logs.blank?
      flash[:alert] = t('inventories.update.message.nothing_saved')
    else
      flash[:notice] = t('inventories.update.message.success')
    end

  end

  # atomatically handle pool if it's only one
  def pool_selection
    if current_property.single_pool?
      pool = current_property.pools.first
      redirect_to grid_inventories_path(:pool_id => pool.id)
    end
  end

  # handle selected pool
  def set_pool
    if params[:pool_id].blank?
      redirect_to inventories_pool_selection_path
    else
      @pool = Pool.find(params[:pool_id])
    end
  end

  private

  # validate inventory value given
  def validate_inventory_date
    result = true
    errors = Array.new
    current_property.room_types.each do |rt|
      if params["#{rt.id}"]
        current_property.account.rate_types.each do |rate_type|
          if params["#{rt.id}"]["#{rate_type.id}"]
            params["#{rt.id}"]["#{rate_type.id}"].each do |date_inv|
              total_rooms = date_inv[1]
              # value must be positive number
              if !(total_rooms =~ /\A[-+]?[0-9]*\.?[0-9]+\Z/)
                errors << t('inventories.validate.error_not_a_number', :room_type => rt.name, :date => date_inv[0])
              elsif total_rooms.to_i < 0
                errors << t('inventories.validate.error_negative_number', :room_type => rt.name, :date => date_inv[0])
              end
            end
          end
        end
      end
    end

    if !errors.empty?
      flash[:alert] = errors
      result = false
    end

    result
  end

  # handle date params specified for the form
  def handle_date
    today = DateTime.now.beginning_of_day.to_date
    @max_end = today + 400.days
    @inv_start = today
    @master_rates_start = today
    @agoda_rates_start = today
    @expedia_rates_start = today
    @bookingcom_rates_start = today
    @gta_travel_rates_start = today
    @orbitz_rates_start = today
    @ctrip_rates_start = today

    begin
      # set the date in inventory table
      @inv_start = Date.strptime(params[:inv_start]) unless params[:inv_start].blank?
      @inv_start = today if @inv_start < today
      @inv_start = @max_end if @inv_start > @max_end

      # set the date in master rate table
      @master_rates_start = Date.strptime(params[:master_rates_start]) unless params[:master_rates_start].blank?
      @master_rates_start = today if @master_rates_start < today
      @master_rates_start = @max_end if @master_rates_start > @max_end

      # set the date in agoda rates table
      @agoda_rates_start = Date.strptime(params[:agoda_rates_start]) unless params[:agoda_rates_start].blank?
      @agoda_rates_start = today if @agoda_rates_start < today
      @agoda_rates_start = @max_end if @agoda_rates_start > @max_end

      # set the date in expedia rates table
      @expedia_rates_start = Date.strptime(params[:expedia_rates_start]) unless params[:expedia_rates_start].blank?
      @expedia_rates_start = today if @expedia_rates_start < today
      @expedia_rates_start = @max_end if @expedia_rates_start > @max_end

      # set the date in booking.com table
      @bookingcom_rates_start = Date.strptime(params[:bookingcom_rates_start]) unless params[:bookingcom_rates_start].blank?
      @bookingcom_rates_start = today if @bookingcom_rates_start < today
      @bookingcom_rates_start = @max_end if @bookingcom_rates_start > @max_end

      # set the date in gta travel
      @gta_travel_rates_start = Date.strptime(params[:gta_travel_rates_start]) unless params[:gta_travel_rates_start].blank?
      @gta_travel_rates_start = today if @gta_travel_rates_start < today
      @gta_travel_rates_start = @max_end if @gta_travel_rates_start > @max_end

      # set the date in orbitz
      @orbitz_rates_start = Date.strptime(params[:orbitz_rates_start]) unless params[:orbitz_rates_start].blank?
      @orbitz_rates_start = today if @orbitz_rates_start < today
      @orbitz_rates_start = @max_end if @orbitz_rates_start > @max_end

      # set the date in ctrip
      @ctrip_rates_start = Date.strptime(params[:ctrip_rates_start]) unless params[:ctrip_rates_start].blank?
      @ctrip_rates_start = today if @ctrip_rates_start < today
      @ctrip_rates_start = @max_end if @ctrip_rates_start > @max_end
    
    rescue => ex
      flash[:alert] = ex.message
    end
  end

  # create log/version for each inventory changes
  def create_inventory_log(inventory)
    MemberSetInventoryLog.create(:inventory_id => inventory.id, :total_rooms => inventory.total_rooms)
  end
  
end
