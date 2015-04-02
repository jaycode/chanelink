# handle currency conversion menu
class CurrencyConversionController < ApplicationController

  before_filter :member_authenticate_and_property_selected

  # handle currency conversion changes
  def submit
    current_property.currency_conversion_enabled = params[:currency_conversion] == 'enabled' ? true : false
    current_property.save
    flash[:notice] = t('currency_conversion.submit.message.success')
    redirect_to edit_currency_conversion_path
  end

  def index
    get_data
  end

  def edit
    get_data
  end

  private

  # get all the currency conversion already defined for this property
  def get_data
    @currency_conversions = CurrencyConversion.property_channel_ids(current_property.channels.collect &:id)
  end

end
