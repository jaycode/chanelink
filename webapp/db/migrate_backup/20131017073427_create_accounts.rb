class CreateAccounts < ActiveRecord::Migration
  def self.up
    create_table :accounts do |t|
      t.string :name
      t.text :address
      t.string :telephone
      t.timestamps
    end

    add_index(:accounts, :id, :unique => true)
  end

  def self.down
    drop_table :accounts
  end
end
