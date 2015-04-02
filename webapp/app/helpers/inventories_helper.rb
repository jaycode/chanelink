module InventoriesHelper

  # generate inventory field name
  def generate_original_inventory_field_value(date, room_type)
    "original#{generate_inventory_field_name(date, room_type)}"
  end

  # generate inventory field name
  def generate_inventory_field_name(date, room_type)
    "[#{room_type.id}][#{date.strftime('%F')}]"
  end

  # generate rates field name
  def generate_rates_field_name(date, room_type, field)
    "[#{room_type.id}][#{date.strftime('%F')}][#{field}]"
  end

  # generate rates field name
  def generate_rates_field_name_no_room_type(date, field)
    "[#{field}][#{date.strftime('%F')}]"
  end

  # inventory grid date picker
  def inventory_date_picker_js(field_id, pool_id)
    parameter = {
      :minDate => 0,
      :dateFormat => "yy-mm-dd",
      :maxDate => "+400D"
    }
    javascript_tag "$(function() {
        $( \"\##{field_id}\" ).datepicker(#{parameter.to_json});
        $( \"\##{field_id}\" ).change(function(){
          url = '#{grid_inventories_url}' + '?inv_start=' + this.value + '&pool_id=' + #{pool_id};
          window.location.replace(url);
        });
      });"
  end

  # inventory grid date picker
  def master_rates_date_picker_js(field_id, pool_id)
    parameter = {
      :minDate => 0,
      :dateFormat => "yy-mm-dd",
      :maxDate => "+400D"
    }
    javascript_tag "$(function() {
        $( \"\##{field_id}\" ).datepicker(#{parameter.to_json});
        $( \"\##{field_id}\" ).change(function(){
          url = '#{grid_inventories_url}' + '?master_rates_start=' + this.value + '&pool_id=' + #{pool_id};
          window.location.replace(url);
        });
      });"
  end

  # inventory grid date picker
  def agoda_rates_date_picker_js(field_id, pool_id)
    parameter = {
      :minDate => 0,
      :dateFormat => "yy-mm-dd",
      :maxDate => "+400D"
    }
    javascript_tag "$(function() {
        $( \"\##{field_id}\" ).datepicker(#{parameter.to_json});
        $( \"\##{field_id}\" ).change(function(){
          url = '#{grid_inventories_url}' + '?agoda_rates_start=' + this.value + '&pool_id=' + #{pool_id};
          window.location.replace(url);
        });
      });"
  end

  # inventory grid date picker
  def expedia_rates_date_picker_js(field_id, pool_id)
    parameter = {
      :minDate => 0,
      :dateFormat => "yy-mm-dd",
      :maxDate => "+400D"
    }
    javascript_tag "$(function() {
        $( \"\##{field_id}\" ).datepicker(#{parameter.to_json});
        $( \"\##{field_id}\" ).change(function(){
          url = '#{grid_inventories_url}' + '?expedia_rates_start=' + this.value + '&pool_id=' + #{pool_id};
          window.location.replace(url);
        });
      });"
  end

  # inventory grid date picker
  def bookingcom_rates_date_picker_js(field_id, pool_id)
    parameter = {
      :minDate => 0,
      :dateFormat => "yy-mm-dd",
      :maxDate => "+400D"
    }
    javascript_tag "$(function() {
        $( \"\##{field_id}\" ).datepicker(#{parameter.to_json});
        $( \"\##{field_id}\" ).change(function(){
          url = '#{grid_inventories_url}' + '?bookingcom_rates_start=' + this.value + '&pool_id=' + #{pool_id};
          window.location.replace(url);
        });
      });"
  end

  # inventory grid date picker
  def gta_travel_rates_date_picker_js(field_id, pool_id)
    parameter = {
      :minDate => 0,
      :dateFormat => "yy-mm-dd",
      :maxDate => "+400D"
    }
    javascript_tag "$(function() {
        $( \"\##{field_id}\" ).datepicker(#{parameter.to_json});
        $( \"\##{field_id}\" ).change(function(){
          url = '#{grid_inventories_url}' + '?gta_travel_rates_start=' + this.value + '&pool_id=' + #{pool_id};
          window.location.replace(url);
        });
      });"
  end

  # inventory grid date picker
  def orbitz_rates_date_picker_js(field_id, pool_id)
    parameter = {
      :minDate => 0,
      :dateFormat => "yy-mm-dd",
      :maxDate => "+400D"
    }
    javascript_tag "$(function() {
        $( \"\##{field_id}\" ).datepicker(#{parameter.to_json});
        $( \"\##{field_id}\" ).change(function(){
          url = '#{grid_inventories_url}' + '?orbitz_rates_start=' + this.value + '&pool_id=' + #{pool_id};
          window.location.replace(url);
        });
      });"
  end

  # stop sell checkbox toggle
  def stop_sell_toggle
    javascript_tag "$(function() {
        $( \".#{UiConstant::STOP_SELL_TOGGLE}\" ).change(function(){
          all_stop_sell = $(this).parent().parent().siblings('.#{UiConstant::STOP_SELL_CLASS}');
          if ($(this).is(':checked')) {
            all_stop_sell.show();
          } else {
            all_stop_sell.hide();
          }
        });
      });"
  end

  # min stay checkbox toggle
  def min_stay_toggle
    javascript_tag "$(function() {
        $( \".#{UiConstant::MIN_STAY_TOGGLE}\" ).change(function(){
          all_min_stay = $(this).parent().parent().siblings('.#{UiConstant::MIN_STAY_CLASS}');
          if ($(this).is(':checked')) {
            all_min_stay.show();
          } else {
            all_min_stay.hide();
          }
        });
      });"
  end

  # cta checkbox toggle
  def cta_toggle
    javascript_tag "$(function() {
        $( \".#{UiConstant::CTA_TOGGLE}\" ).change(function(){
          all_cta = $(this).parent().parent().siblings('.#{UiConstant::CTA_CLASS}');
          if ($(this).is(':checked')) {
            all_cta.show();
          } else {
            all_cta.hide();
          }
        });
      });"
  end

  # ctd checkbox toggle
  def ctd_toggle
    javascript_tag "$(function() {
        $( \".#{UiConstant::CTD_TOGGLE}\" ).change(function(){
          all_ctd = $(this).parent().parent().siblings('.#{UiConstant::CTD_CLASS}');
          if ($(this).is(':checked')) {
            all_ctd.show();
          } else {
            all_ctd.hide();
          }
        });
      });"
  end

  # cta checkbox toggle
  def gta_travel_cta_toggle
    javascript_tag "$(function() {
        $( \".#{UiConstant::GTA_TRAVEL_CTA_TOGGLE}\" ).change(function(){
          all_cta = $(this).parent().parent().siblings('.#{UiConstant::GTA_TRAVEL_CTA_CLASS}');
          if ($(this).is(':checked')) {
            all_cta.show();
          } else {
            all_cta.hide();
          }
        });
      });"
  end

  # ctd checkbox toggle
  def gta_travel_ctb_toggle
    javascript_tag "$(function() {
        $( \".#{UiConstant::GTA_TRAVEL_CTB_TOGGLE}\" ).change(function(){
          all_ctb = $(this).parent().parent().siblings('.#{UiConstant::GTA_TRAVEL_CTB_CLASS}');
          if ($(this).is(':checked')) {
            all_ctb.show();
          } else {
            all_ctb.hide();
          }
        });
      });"
  end

  def store_previously_selected_js
    javascript_tag "$(function() {
        $('input').focusout(function () {
           $(this).closest('form').data('lastSelected', $(this));
        });
      });"
  end

  # copy across for inventory grid
  def copy_across_js
    javascript_tag "$(function() {

        $(\"\.copyAcross\" ).click(function(){

          form = $(this).closest('form');
          last_selected = form.data('lastSelected');

          if (last_selected !== undefined) {
            name = last_selected.attr('name');
            splitted = name.split(']')

            if (splitted.length > 2) {
              rt_name = splitted[0] + ']';
              min_stay = splitted[2] + ']';

              value_to_copy = last_selected.val();

              form.find(\"input[name^='\" + rt_name + \"']\" + \"[name$='\" + min_stay + \"']\").each(function() {
                if (!$(this).is(':disabled')) {
                  $(this).val(value_to_copy);
                }
              });
            } else {
              rt_name = splitted[0] + ']';

              value_to_copy = last_selected.val();

              form.find(\"input[name^='\" + rt_name + \"']\").each(function() {
                if (!$(this).is(':disabled')) {
                  $(this).val(value_to_copy);
                }
              });
            }
          }
          return false;
        });
      });"
  end

  # copy up/down for inventory grid
  def copy_up_down_js
    javascript_tag "$(function() {

        $(\"\.copyUpdown\" ).click(function(){

          form = $(this).closest('form');
          last_selected = form.data('lastSelected');

          if (last_selected !== undefined) {
            name = last_selected.attr('name');
            date_name = name.split(']')[1] + ']';

            value_to_copy = last_selected.val();

            form.find(\"input[name$='\" + date_name + \"']\").each(function() {
              if (!$(this).is(':disabled')) {
                $(this).val(value_to_copy);
              }
            });
          }
          return false;
        });
      });"
  end

  def determine_master_rate_amount(date, room_type, pool_id, flash)
    amount = 0
    if flash[:master_rates] and flash[:master_rates][room_type.id.to_s]
      amount = flash[:master_rates][room_type.id.to_s][DateUtils.date_to_key(date)]['amount']
    else
      rate = MasterRate.find_by_date_and_property_id_and_pool_id_and_room_type_id(date, current_property.id, pool_id, room_type.id)
      amount = rate.amount unless rate.blank?
    end
    amount
  end

  def determine_channel_rate_amount(date, room_type, channel, pool_id, flash)
    amount = 0
    channel_key = "#{channel.cname}_rates"
    if flash[channel_key] and flash[channel_key][room_type.id.to_s]
      amount = flash[channel_key][room_type.id.to_s][DateUtils.date_to_key(date)]['amount']
    else
      puts "#{date} #{current_property.id} #{pool_id} #{room_type.id} #{channel.id}"
      rate = ChannelRate.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(date, current_property.id, pool_id, room_type.id, channel.id)
      puts rate
      amount = rate.amount unless rate.blank?
    end
    amount
  end

  def determine_channel_rate_min_stay(date, room_type, channel, pool_id, flash)
    min_stay = 0
    channel_key = "#{channel.cname}_rates"
    if flash[channel_key] and flash[channel_key][room_type.id.to_s]
      min_stay = flash[channel_key][room_type.id.to_s][DateUtils.date_to_key(date)]['min_stay']
    else
      rate = ChannelMinStay.find_by_date_and_property_id_and_pool_id_and_room_type_id_and_channel_id(date, current_property.id, pool_id, room_type.id, channel.id)
      min_stay = rate.min_stay unless rate.blank?
    end
    min_stay
  end

end
