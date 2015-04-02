class AddGtaTravelContractIdToPropertyChannels < ActiveRecord::Migration
  def self.up
    add_column :property_channels, :gta_travel_contract_id, :string
  end

  def self.down
    remove_column :property_channels, :gta_travel_contract_id
  end
end
