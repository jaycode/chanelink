class CreateAlerts < ActiveRecord::Migration
  def self.up
    create_table :alerts do |t|
      t.column :receiver_id, :integer, :null => false, :references => :members
      t.integer :data_id
      t.string :type
      t.column :read, :boolean, :default => false
      t.boolean :deleted, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :alerts
  end
end
