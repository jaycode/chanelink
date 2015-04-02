class AddPromptPasswordChangeToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :prompt_password_change, :boolean, :default => true
  end

  def self.down
    remove_column :users, :prompt_password_change
  end
end
