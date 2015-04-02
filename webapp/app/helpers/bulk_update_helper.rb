module BulkUpdateHelper

  # handle value field change
  def toggle_room_type_field_js
    javascript_tag "$(function() {
        $(\"input[name='bu[room_type_ids][]']\").change(function(e){
          updateChannelList();
          return false;
      });
    });"
  end

  # handle value room type field change
  def toggle_value_field_js
    javascript_tag "$(function() {
        $(\"input[name='bu[value_type]']\").change(function(e){
          $('.radioField').hide();
          $(\".\" + $(this).val()).show();
      });
    });"
  end

  # bulk update date picker
  def bulk_update_date_picker_js(field_id)
    parameter = {
      :minDate => 0,
      :dateFormat => "yy-mm-dd",
      :maxDate => "+400D"
    }
    javascript_tag "$(function() {
        $( \"\##{field_id}\" ).datepicker(#{parameter.to_json});
      });"
  end

  # select all day
  def days_select_all_js
    javascript_tag "$(function() {
      $('#daysSelectAll').click(function() {
        var checkboxes = $(this).parent().next().find(':checkbox');
        checkboxes.attr('checked', 'checked');
        return false;
      });
    });"
  end

  # room type select all
  def room_types_select_all_js
    javascript_tag "$(function() {
      $('#roomTypesSelectAll').click(function() {
        var checkboxes = $(this).parent().next().find(':checkbox');
        checkboxes.attr('checked', 'checked');
        updateChannelList();
        return false;
      });
    });"
  end

  # update channel list after pool select
  def pools_select_notify_js
    javascript_tag "$(function() {
      $('#bu_pool_id').change(function() {
        updateChannelList();
      });
    });"
  end

  # update channel list after master rate select
  def master_rate_select_notify_js
    javascript_tag "$(function() {
      $('#bu_apply_to_master_rate').change(function() {
        updateChannelList();
      });
    });"
  end

  # update channel list after value type
  def value_type_select_notify_js
    javascript_tag "$(function() {
      $(\"input[name=\'bu[value_type]\']\").change(function() {
        selected = $(\"input[name=\'bu[value_type]\']:checked\").val();
        if (selected == '#{BulkUpdate::VALUE_RATES}') {
          $('.applyToMasterRate').show();
        } else {
          $('#bu_apply_to_master_rate').prop('checked', false);
          $('.applyToMasterRate').hide();
        }
        updateChannelList();
        updateRoomTypeList();
      });
    });"
  end

  def update_room_types_list_js
    javascript_tag "
      function updateRoomTypeList() {
        selected = $(\"input[name=\'bu[value_type]\']:checked\").val();
        if (selected == '#{BulkUpdate::VALUE_CTB}') {
          $('.roomTypesCheckbox').find(':checkbox').each(function () {
            $(this).attr('disabled', true);
            $(this).attr('checked', true);
            $(this).parent().addClass('disabled');
          });
        } else {
          $('.roomTypesCheckbox').find(':checkbox').each(function () {
            $(this).attr('disabled', false);
            $(this).attr('checked', false);
            $(this).parent().removeClass('disabled');
          });
        }
      }"
  end

  # update channel list 
  def update_channels_list_js
    javascript_tag "
      var poolsChannels = new Hashtable();
      #{update_channels_list_data}
      function updateChannelList() {
        key = $('#bu_pool_id').val();
        enabled_list = poolsChannels.get(key);
        
        value_type = $(\"input[name=\'bu[value_type]\']:checked\").val();
        if (value_type == '#{BulkUpdate::VALUE_AVAILABILITY}') {
          enabled_list = [];
        } else if (value_type == '#{BulkUpdate::VALUE_CTA}') {
          if (jQuery.inArray(gta_travel_channel_id, enabled_list)) {
            if ($(\"input[name=\'bu[room_type_ids][]\']:checked\").length != $(\"input[name=\'bu[room_type_ids][]\']\").length) {
              enabled_list = jQuery.grep(enabled_list, function(value) {
                return value != gta_travel_channel_id;
              });
            }
          }

          enabled_list = jQuery.grep(enabled_list, function(value) {
            return (cta_enabled.indexOf(parseInt(value)) > -1);
          });
        } else if (value_type == '#{BulkUpdate::VALUE_CTD}') {
          enabled_list = jQuery.grep(enabled_list, function(value) {
            return (ctd_enabled.indexOf(parseInt(value)) > -1);
          });
        } else if (value_type == '#{BulkUpdate::VALUE_CTB}') {
          enabled_list = jQuery.grep(enabled_list, function(value) {
            return value == gta_travel_channel_id;
          });
        }

        master_rate = $('#bu_apply_to_master_rate');
        if (master_rate.is(':checked')) {
          enabled_list = [];
        }

        $('.channelsCheckbox').find(':checkbox').each(function () {
          if(enabled_list.indexOf(parseInt($(this).val())) < 0) {
            $(this).attr('disabled', true);
            $(this).attr('checked', false);
            $(this).parent().addClass('disabled');
          } else {
            $(this).attr('disabled', false);
            $(this).parent().removeClass('disabled');
          }
        });
      }
      $(document).ready(function() {
        updateChannelList();
        updateRoomTypeList();
      });"
  end

  # update list of channel allowed for cta, ctd
  def update_channels_list_data
    result = ""

    result << "var pool_all = [#{(current_property.channels.collect &:channel_id).join(',')}];"
    result << "poolsChannels.put('all', pool_all);"

    current_property.pools.each do |pool|
      result << "var pool_#{pool.id} = [#{(pool.channels.collect &:channel_id).join(',')}];"
      result << "poolsChannels.put('#{pool.id}', pool_#{pool.id});"
    end
    result << "var cta_enabled = [#{((Constant::SUPPORT_CTA.collect &:id) + (Constant::SUPPORT_GTA_TRAVEL_CHANNEL_CTA.collect &:id)).join(',')}];"
    result << "var ctd_enabled = [#{(Constant::SUPPORT_CTD.collect &:id).join(',')}];"
    result << "var gta_travel_channel_id = #{GtaTravelChannel.first.id}" if GtaTravelChannel.all.count > 0
    result
  end
  
end
