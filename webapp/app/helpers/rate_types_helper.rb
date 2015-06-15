module RateTypesHelper

  # popup warning for deleting rate type mapping
  def delete_rate_type_dialog_body(rate_type)
    channel_name = Array.new
    RoomTypeChannelMapping.find_all_by_rate_type_id(rate_type.id).each do |rtcm|
      channel_name << rtcm.channel.name
    end

    channel_display = channel_name.empty? ? I18n.t('rate_types.delete.dialog.no_channel') : channel_name.join(', ')

    escape_javascript "<p><strong>#{I18n.t('rate_types.delete.dialog.permanent', :rate_type => rate_type.name)}</strong></p>
      <p>#{I18n.t('rate_types.delete.dialog.all_data', :rate_type => rate_type.name)}</p>
      <p>- #{channel_display}</p>
      <p>#{I18n.t('rate_types.delete.dialog.does_not_delete', :rate_type => rate_type.name)}</p>
      <p><input id='confirm_delete' type='checkbox'/>&nbsp;&nbsp;#{I18n.t('rate_types.delete.dialog.confirm_delete', :rate_type => rate_type.name)}"
  end

end