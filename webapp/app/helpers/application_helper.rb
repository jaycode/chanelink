module ApplicationHelper

  # used to render page heading but will set title page too
  def page_title(title = nil)
    if title
      content_for(:page_title) { title }
    else
      content_for?(:page_title) ? content_for(:page_title) : t('default_page_title') # or default page title
    end
  end

  # collect flash messages into series of <p> tag
  def collect_flash_messages(symbol)
    notices = ''
    msg = nil

    if symbol.is_a? Array
      combine = Array.new
      symbol.each do |s|
        combine << flash[s] unless flash[s].blank?
      end
      msg = combine.flatten
    else
      msg = flash[symbol]
    end

    if msg.is_a?(Array)
      msg.each do |m|
        notices += '<p>' + m + '</p>'
      end
    else
      notices += '<p>' + msg + '</p>'
    end
    notices
  end

  # check sub menu in dashboard
  def check_selected_sub_menu(param)
    param.each do |path|
      return true if current_page?(path)
    end
    return false
  end

  # check if date is weekend or not
  def is_date_weekend?(date)
    if date.wday == 0 or date.wday == 6
      return true
    else
      return false
    end
  end

  # popup warning for channel mapping delete
  def delete_channel_mapping_dialog_body(room_type, channel)
    escape_javascript "<p><strong>#{I18n.t('room_type_channel_mappings.delete.dialog.paragraph_a', :room_type => room_type.name, :channel => channel.name)}</strong></p>
     <p>#{I18n.t('room_type_channel_mappings.delete.dialog.paragraph_b', :room_type => room_type.name, :channel => channel.name)}</p>
     <p>#{I18n.t('room_type_channel_mappings.delete.dialog.paragraph_c')}</p>
     <p><input id='confirm_delete' type='checkbox'/>&nbsp;&nbsp;#{I18n.t('room_type_channel_mappings.delete.dialog.paragraph_d')}"
  end

  # popup warning for account delete
  def delete_account_dialog_body
    escape_javascript "<p><strong>#{I18n.t('admin.accounts.delete.dialog.body')}</strong></p>"
  end

  # popup warning for property delete
  def delete_property_dialog_body
    escape_javascript "<p><strong>#{I18n.t('admin.properties.delete.dialog.body')}</strong></p>"
  end

  # required label
  def required
    raw "<span class='red'>&nbsp;*</span>"
  end

  # pretty print number to IDR currency
  def idr_currency(amount)
    number_to_currency(amount, :unit => I18n.t('currency.idr'), :precision => 0)
  end

  # refresh page after selecting a pool
  def pool_selection_js(path)
    javascript_tag "$(function() {
      $('#select_pool').change(function() {
        pool_id = $(this).val();
        window.location = '#{path}?pool_id=' + pool_id;
      });
    });"
  end

  # only allow numeric for a text field
  def numeric_only_input_js
    javascript_tag "$(function() {
        jQuery.fn.ForceNumericOnly =
        function()
        {
            return this.each(function()
            {
                $(this).keydown(function(e)
                {
                    var key = e.charCode || e.keyCode || 0;
                    // allow backspace, tab, delete, arrows, numbers and keypad numbers ONLY
                    // home, end, period, and numpad decimal
                    return (
                        key == 8 ||
                        key == 9 ||
                        key == 46 ||
                        key == 110 ||
                        key == 190 ||
                        (key >= 35 && key <= 40) ||
                        (key >= 48 && key <= 57) ||
                        (key >= 96 && key <= 105));
                });
            });
        };
        $('.numericOnly').ForceNumericOnly();
    });"
  end

  def bookingcom_update_date_picker_js(field_id)
    parameter = {
      :minDate => 0,
      :dateFormat => "yy-mm-dd",
      :maxDate => "+400D"
    }
    javascript_tag "$(function() {
        $( \"\##{field_id}\" ).datepicker(#{parameter.to_json});
      });"
  end
  
  # refresh page after selecting account
  def account_selection_js(path)
    javascript_tag "$(function() {
      $('#select_account').change(function() {
        account_id = $(this).val();
        window.location = '#{path}?account_id=' + account_id;
      });
    });"
  end

  # select all day
  def broadcast_alert_select_all_js
    javascript_tag "$(function() {
      $('#broadcastAlertSelectAll').click(function() {
        var checkboxes = $('.propertyCheck' ).find(':checkbox');
        checkboxes.attr('checked', 'checked');
        return false;
      });
    });"
  end


end
