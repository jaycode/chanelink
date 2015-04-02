module RoomTypeMasterRateChannelMappingsHelper

  # toggle value/percentage field
  def master_rate_radio_js
    javascript_tag "$(function() {
        $(\"input[name='room_type_master_rate_channel_mapping[method]']\").change(function(e){
          if($(this).val() == '#{RoomTypeMasterRateChannelMapping::PERCENTAGE}') {
              $('.percentage').show();
              $('.amount').hide();
          } else {
              $('.amount').show();
              $('.percentage').hide();
          }
      });
    });"
  end
end
