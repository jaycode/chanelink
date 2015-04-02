# controller for availability linking module
class RoomTypeInventoryLinksController < ApplicationController

  before_filter :member_authenticate_and_property_selected

  # form for new link
  def new
    @link = RoomTypeInventoryLink.new
    @link.room_type_from = RoomType.find(params[:room_type_from_id])
  end

  # create the new availability linking
  def create
    @link = RoomTypeInventoryLink.new(params[:room_type_inventory_link])
    @link.property = current_property
    if @link.valid?
      @link.save

      # after linking, sync the new availability
      RoomTypeChannelMapping.find_all_by_room_type_id(@link.room_type_to_id).each do |rtcm|
        rtcm.sync_availability
      end
      
      redirect_to room_type_inventory_links_path
    else
      put_model_errors_to_flash(@link.errors)
      render 'new'
    end
  end

  # delete availability link
  def delete
    @link = RoomTypeInventoryLink.find(params[:id])
    @link.deleted = true
    @link.save
    
    # copy current source room type availability
    copy_inventory(@link)
    
    flash[:notice] = t('room_type_inventory_links.delete.message.success')
    redirect_to room_type_inventory_links_path
  end
  
  private

  # copy availability from source to destination room type
  def copy_inventory(link)
    room_type_from = link.room_type_from
    room_type_to = link.room_type_to
    current_property.pools.each do |pool|
      loop_date = DateTime.now.in_time_zone.beginning_of_day

      # copy for the next 400 days
      while loop_date <= Constant.maximum_end_date
        from_inventory = Inventory.find_by_date_and_property_id_and_pool_id_and_room_type_id(loop_date, current_property.id, pool.id, room_type_from.id)
        to_inventory = Inventory.find_by_date_and_property_id_and_pool_id_and_room_type_id(loop_date, current_property.id, pool.id, room_type_to.id)

        inventory_to_use = to_inventory.blank? ? 0 : to_inventory.total_rooms

        # copy the inventory object
        if from_inventory.blank?
          inventory = Inventory.new
          inventory.date = loop_date
          inventory.total_rooms = inventory_to_use
          inventory.room_type_id = room_type_from.id
          inventory.property = current_property
          inventory.pool_id = pool.id

          inventory.save
        else
          from_inventory.update_attribute(:total_rooms, inventory_to_use)
        end

        loop_date = loop_date + 1.day
      end
    end
  end
  
end
