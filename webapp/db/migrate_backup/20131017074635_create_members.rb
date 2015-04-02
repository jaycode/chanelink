class CreateMembers < ActiveRecord::Migration
  def self.up
    create_table :members do |t|
      t.string :email
      t.text :name
      t.string :hashed_password
      t.string :salt
      t.belongs_to :role
      t.belongs_to :account
      t.boolean :prompt_password_change, :default => true
      t.boolean :disabled, :default => false
      t.boolean :deleted, :default => false
      t.boolean :master, :default => false
      t.timestamps
    end
    add_index(:members, :id, :unique => true)
  end

  def self.down
    drop_table :members
  end
end
