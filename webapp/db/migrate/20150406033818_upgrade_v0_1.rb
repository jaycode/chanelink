class UpgradeV01 < ActiveRecord::Migration
  def self.up
    # We put all db migrations needed for upgrade in this dir.
    # The difference between migrations and seed is we can run (only up!) migrations on production
    # but not seeds.rb

    # Todo: Perhaps in future we move all channel related data into
    #       some config file.
    ctrip = Channel.create do |c|
      c.name = 'Ctrip'
      c.type = 'CtripChannel'
    end

    add_column :property_channels, :settings, :string, :default => ActiveSupport::JSON.encode({__default: {}})
  end

  def self.down
    Channel.destroy_all(name: 'Ctrip')
  end
end
