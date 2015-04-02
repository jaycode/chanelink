class AddNewAttributesToAccounts < ActiveRecord::Migration
  def self.up
    add_column :accounts, :contact_name, :string
    add_column :accounts, :contact_email, :string
    add_column :accounts, :disabled, :boolean, :default => false
  end

  def self.down
    remove_column :accounts, :contact_name
    remove_column :accounts, :contact_email
    remove_column :accounts, :disabled
  end
end
