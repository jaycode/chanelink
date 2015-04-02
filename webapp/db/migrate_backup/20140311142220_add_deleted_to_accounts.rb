class AddDeletedToAccounts < ActiveRecord::Migration
  def self.up
    add_column :accounts, :deleted, :boolean, :default => false
  end

  def self.down
    remove_column :accounts, :deleted
  end
end
