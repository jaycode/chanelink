class UpgradeV0.1 < ActiveRecord::Migration
  def self.up
    # We put all db migrations needed for upgrade in this dir.
    # The difference between migrations and seed is we can run (only up!) migrations on production
    # but not seeds.rb

    # Todo: Perhaps in future we move all channel related data into
    #       some config file.
    ctrip = Ctrip.create do |c|
      c.name = 'Ctrip'
      c.type = 'CtripChannel'
    end

  end

  def self.down
  end
end
