module RoomTypeMasterRateMappingsHelper

  # popup to create new master rate
  def new_master_rate_mappings_dialog_body(pool)
    already_created = @pool.master_rate_mappings.collect {|mrp| "#{mrp.room_type_id}:#{mrp.rate_type_id}"}
    not_created = Array.new

    current_property.room_types.each do |rt|
      current_property.account.rate_types.each do |rate_type|
        not_created << "#{rt.id}:#{rate_type.id}" unless already_created.include?("#{rt.id}:#{rate_type.id}")
      end
    end

    unless not_created.blank?
      s = form_tag(room_type_master_rate_mappings_path, :class => 'new_master_rate_mappings') do
        body = hidden_field_tag(:pool_id, pool.id);
        not_created.each do |rt_id|
          body << content_tag(:div) do
            check_box_row = check_box_tag("room_rate_type_ids[]", rt_id, false,
                                          :id => "room_rate_type_#{rt_id.sub(':', '-')}",
                                          :class => 'room_rate_type_ids_check')
            check_box_row << "  #{RoomType.find(rt_id.split(':')[0]).name} (#{RateType.find(rt_id.split(':')[1]).name})"
          end
        end
        body
      end
      s.html_safe
    end
  end

  # popup warning before deleting master rate mapping
  def delete_master_rate_mappings_dialog_body(master_rate_mapping)
    body = content_tag(:p) do
      t('room_type_master_rate_mappings.delete.label.confirm', :room_type => master_rate_mapping.room_type.name)
    end
    body.html_safe
  end

  def delete_warning_master_rate_mappings_dialog_body(master_rate_mapping)
    body = content_tag(:p) do
      t('room_type_master_rate_mappings.delete.label.channel_map_exist', :room_type => master_rate_mapping.room_type.name)
    end
    master_rate_mapping.channel_mappings.each do |cm|
      body << content_tag(:p) do
        "  - #{cm.channel.name}"
      end
    end
    body.html_safe
  end
  
end
