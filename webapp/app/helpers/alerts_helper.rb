module AlertsHelper

  # helper to select all alerts
  def alerts_select_all_js
    javascript_tag "$(function() {
      $('#alertsSelectAll').click(function() {
        var checkboxes = $(this).parent().parent().nextAll().find(':checkbox');
        if ($(this).prop('checked')) {
          checkboxes.attr('checked', 'checked');
        } else {
          checkboxes.attr('checked', false);
        }
        return true;
      });
    });"
  end
  
end
