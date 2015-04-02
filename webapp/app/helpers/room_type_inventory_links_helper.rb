module RoomTypeInventoryLinksHelper

  # popup for new availability link
  def new_room_type_inventory_links_dialog_body(rt)
    s = form_tag(room_type_inventory_links_path, :class => 'new_room_type_inventory_links') do
      body = hidden_field_tag 'room_type_inventory_link[room_type_from_id]', rt.id
      body << content_tag(:p) do
        room_type_row_a = label_tag t('room_type_inventory_links.new.label.room_type')
        room_type_row_a << " #{rt.name}"
      end
      body << content_tag(:p) do
        room_type_row = label_tag t('room_type_inventory_links.new.label.link')
        room_type_row << (raw select_tag("room_type_inventory_link[room_type_to_id]", options_for_select(RoomTypeInventoryLink.select_list(current_property, rt), nil)).gsub("\n", "\\n").gsub("'","\\'"))
      end
      body
    end
    puts s.html_safe
    s.html_safe
  end
  
end
