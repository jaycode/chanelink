class CreateCurrencies < ActiveRecord::Migration
  def self.up
    create_table :currencies do |t|
      t.string :code
      t.string :name
      t.timestamps
    end
    add_index(:currencies, :id, :unique => true)

    File.open("#{Rails.root}/db/curr.txt", "r") do |infile|
     
      infile.read.each_line do |currency_row|
        code, name = currency_row.chomp.split(",")
        currency = Currency.new
        currency.code = code
        currency.name = name
        currency.save
      end
    end
  end

  def self.down
    drop_table :currencies
  end
end
