# To change this template, choose Tools | Templates
# and open the template in the editor.

module PropertyChannelsHelper
  def get_unmapped_rooms(property, channel)
    rooms = Array.new
    property.room_types.each do |rt|
      property.account.rate_types.each do |acc_rate_type|
        mapping = RoomTypeChannelMapping.first(
          :conditions => ['room_type_id = ? AND ota_room_type_id IS NOT NULL AND rate_type_id = ? '+
                            'AND ota_rate_type_id IS NOT NULL AND channel_id = ?',
                          rt.id, acc_rate_type.id, channel.id]
        )
        if mapping.blank?
          rooms << {:text => "#{rt.name} (#{acc_rate_type.name})", :id => rt.id, :rate_type_id => acc_rate_type.id}
        end
      end
    end
    rooms
  end
  # use for currency conversion to update value according to exchange rate
  def update_currency_calculation_js
    javascript_tag "
      function updateCurrencyCalculation() {
        to_currency_id = $('#currency_conversion_to_currency_id').val();
        if (to_currency_id != '') {
          $('.calculation').show();
          to_currency = $('#currency_conversion_to_currency_id option:selected').text();
          to_currency_code = to_currency.substring(0, 3);
          $('.toCurrency').text(to_currency_code);

          multiplier = $('#currency_conversion_multiplier').val();

          if ($.isNumeric(multiplier)) {
            $('.baseMultiplier').text(multiplier);
            $('.toMultiplier').text(1.0/multiplier);
          } else {
            $('.baseMultiplier').text(0);
            $('.toMultiplier').text(0);
          }
        } else {
          $('.calculation').hide();
        }
      }
      $(document).ready(function() {
        updateCurrencyCalculation();
      });"
  end

  # recalculate value after multiplier change
  def to_currency_select_notify_js
    javascript_tag "$(function() {
      $('#currency_conversion_to_currency_id').change(function() {
        updateCurrencyCalculation();
      });
    });"
  end

  # recalculate value after multiplier change
  def currency_multiplier_js
    javascript_tag "$(function() {
      $('#currency_conversion_multiplier').keyup(function() {
        updateCurrencyCalculation();
      });
    });"
  end

  def check_pc_disabled_js(submit_id, pc)
    javascript_tag "$(function() {
        $(\"##{submit_id}\").click(function(e){
          disabled_select = $(\"input:radio[name='property_channel[disabled]']:checked\");
          if (disabled_select.val() == 'true') {
            disablePropertyChannelDialog('#{t('property_channels.disabled.label.heading')}', '#{disabled_property_channel_body(pc)}', '#{t('property_channels.disabled.label.confirm')}');
            return false;
          } else {
            return true;
          }
      });
    });"
  end

  def disabled_property_channel_body(pc)
    channel = pc.channel
    body = content_tag(:p) do
      if channel.is_a? BookingcomChannel
        t('property_channels.disabled.label.bookingcom')
      else
        t('property_channels.disabled.label.non_booking')
      end
    end
    body.html_safe
  end

end
