module RoomTypesHelper

  # popup warning for deleting room type mapping
  def delete_room_type_dialog_body(room_type)
    channel_name = Array.new
    RoomTypeChannelMapping.find_all_by_room_type_id(room_type.id).each do |rtcm|
      channel_name << rtcm.channel.name
    end

    channel_display = channel_name.empty? ? I18n.t('room_types.delete.dialog.no_channel') : channel_name.join(', ')
    
    escape_javascript "<p><strong>#{I18n.t('room_types.delete.dialog.permanent', :room_type => room_type.name)}</strong></p>
      <p>#{I18n.t('room_types.delete.dialog.all_data', :room_type => room_type.name)}</p>
      <p>- #{channel_display}</p>
      <p>#{I18n.t('room_types.delete.dialog.does_not_delete', :room_type => room_type.name)}</p>
      <p><input id='confirm_delete' type='checkbox'/>&nbsp;&nbsp;#{I18n.t('room_types.delete.dialog.confirm_delete', :room_type => room_type.name)}"
  end

end
