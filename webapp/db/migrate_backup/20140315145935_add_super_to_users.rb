class AddSuperToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :super, :boolean, :default => false
    #User.all.each do |u|
    #  u.super = true
    #  u.save
    #end
  end

  def self.down
    remove_column :users, :super
  end
end
