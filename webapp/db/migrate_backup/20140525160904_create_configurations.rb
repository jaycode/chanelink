class CreateConfigurations < ActiveRecord::Migration
  def self.up
    create_table :configurations do |t|
      t.integer :days_to_keep_cc_info
      t.timestamps
    end
    Configuration.create(:days_to_keep_cc_info => 7)
  end

  def self.down
    drop_table :configurations
  end
end
