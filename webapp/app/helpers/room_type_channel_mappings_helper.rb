module RoomTypeChannelMappingsHelper

  # show master rate field if master rate type is selected
  def rate_configuration_radio_js
    javascript_tag "$(function() {
        $(\"input[name='room_type_channel_mapping[rate_configuration]']\").change(function(e){
          if($(this).val() == '#{Constant::RTCM_MASTER_RATE}') {
            $('.masterRate').show();
          } else {
            $('.masterRate').hide();
          }
      });
    });"
  end

  def check_rtcm_disabled_js(submit_id, rtcm)
    javascript_tag "$(function() {
        $(\"##{submit_id}\").click(function(e){
          disabled_select = $(\"input:radio[name='room_type_channel_mapping[disabled]']:checked\");
          if (disabled_select.val() == 'true') {
            disableRoomTypeChannelMappingDialog('#{t('room_type_channel_mappings.disabled.label.heading')}', '#{disabled_room_type_channel_mappings_body(rtcm)}', '#{t('room_type_channel_mappings.disabled.label.confirm')}');
            return false;
          } else {
            return true;
          }
      });
    });"
  end

  def disabled_room_type_channel_mappings_body(rtcm)
    channel = rtcm.channel
    body = content_tag(:p) do
      if channel.is_a? BookingcomChannel
        t('room_type_channel_mappings.disabled.label.bookingcom')
      else
        t('room_type_channel_mappings.disabled.label.non_booking')
      end
    end
    body.html_safe
  end

  # show master rate field if master rate type is selected
  def gta_travel_rate_type_radio_js
    javascript_tag "$(function() {
        $(\"input[name='room_type_channel_mapping[gta_travel_rate_type]']\").change(function(e){
          if($(this).val() == '#{GtaTravelChannel::RATE_MARGIN}') {
            $('.gtaTravelMarginRate').show();
          } else {
            $('.gtaTravelMarginRate').hide();
          }
      });
    });"
  end
  
end
