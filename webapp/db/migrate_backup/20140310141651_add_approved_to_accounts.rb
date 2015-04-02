class AddApprovedToAccounts < ActiveRecord::Migration
  def self.up
    add_column :accounts, :approved, :boolean, :default => false
  end

  def self.down
    remove_column :accounts, :approved
  end
end
