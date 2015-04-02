module PoolsHelper

  def new_pool_availability_dialog_body
    escape_javascript "<p><input id='confirm_create' type='checkbox'/>&nbsp;&nbsp;#{I18n.t('pools.new.label.availability_confirmation')}"
  end

  def edit_pool_availability_dialog_body
    escape_javascript "<p><input id='confirm_save' type='checkbox'/>&nbsp;&nbsp;#{I18n.t('pools.new.label.availability_confirmation')}"
  end

end
