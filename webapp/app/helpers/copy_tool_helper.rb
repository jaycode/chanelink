module CopyToolHelper

  # handle pool select change
  def copy_tool_pool_select_js
    javascript_tag "$(function() {
      $('#ct_pool_id').change(function() {
        window.location = '#{copy_tool_path}?pool_id=' + $(this).val();
      });
    });"
  end

  # handle value select change
  def copy_tool_value_type_select_js
    javascript_tag "$(function() {
      $('#ct_value_type').change(function() {
        pool_id = $('#ct_pool_id').val();
        window.location = '#{copy_tool_path}?pool_id=' + pool_id + '&value_type=' + $(this).val();
      });
    });"
  end

  # handle channel from select change
  def copy_tool_channel_from_select_js
    javascript_tag "$(function() {
      $('#ct_channel_id_from').change(function() {
        pool_id = $('#ct_pool_id').val();
        value_type = $('#ct_value_type').val();
        channel_id_to = $('#ct_channel_id_to').val();
        room_id_to = $('#ct_room_id_to').val();
        window.location = '#{copy_tool_path}?pool_id=' + pool_id + '&value_type=' + value_type + '&channel_id_from=' + $(this).val() + '&channel_id_to=' + channel_id_to + '&room_id_to=' + room_id_to;
      });
    });"
  end

  # handle channel to select change
  def copy_tool_channel_to_select_js
    javascript_tag "$(function() {
      $('#ct_channel_id_to').change(function() {
        pool_id = $('#ct_pool_id').val();
        value_type = $('#ct_value_type').val();
        channel_id_from = $('#ct_channel_id_from').val();
        room_id_from = $('#ct_room_id_from').val();
        window.location = '#{copy_tool_path}?pool_id=' + pool_id + '&value_type=' + value_type + '&channel_id_from=' + channel_id_from + '&channel_id_to=' + $(this).val() + '&room_id_from=' + room_id_from;
      });
    });"
  end
  
end
