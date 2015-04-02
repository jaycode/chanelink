module UsersHelper

  # select all property
  def properties_select_all_js
    javascript_tag "$(function() {
      $('#propertiesSelectAll').click(function() {
        var checkboxes = $(this).parent().find(':checkbox');
        if ($(this).prop('checked')) {
          checkboxes.attr('checked', 'checked');
        } else {
          checkboxes.attr('checked', false);
        }
        return true;
      });
    });"
  end

  # hide property selection if super member is selected
  def properties_wrap_toggle_js
    javascript_tag "$(function() {
      $('#user_super').click(function() {
        if ($(this).prop('checked')) {
          $('.propertiesWrap').hide();
        } else {
          $('.propertiesWrap').show();
        }
        return true;
      });
    });"
  end
  
end
