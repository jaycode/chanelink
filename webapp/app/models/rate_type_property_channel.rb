class RateTypePropertyChannel < ActiveRecord::Base
  include HasSettings
  belongs_to :rate_type
  belongs_to :property_channel
  has_many :room_type_master_rate_channel_mappings
  validate :account_similarities

  # Room rate and mapping must have the same account
  def account_similarities
    unless rate_type.account_id == property_channel.property.account_id
      errors.add(:property_channel, I18n.t('rate_types.validate.error_account_similarity'))
    end
  end
end