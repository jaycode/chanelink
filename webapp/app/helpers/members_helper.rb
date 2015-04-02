module MembersHelper

  # toggle field to show when role change
  def role_change_js(field_id)
    javascript_tag "$(function() {
        $( \"\##{field_id}\" ).change(function(){
          if ($(this).val() == '#{MemberRole.super_role.id}') {
            $('.propertiesWrap').hide();
          } else {
            $('.propertiesWrap').show();
          }
        });
      });"
  end
  
end
