class CreateCountries < ActiveRecord::Migration
  def self.up
    create_table :countries do |t|
      t.string :code
      t.string :name
      t.timestamps
    end
    add_index(:countries, :id, :unique => true)

    File.open("#{Rails.root}/db/data/countries.txt", "r") do |infile|
      # specify id explicitly, id starts from 1
      id = 1;
      infile.read.each_line do |country_row|
        code, name = country_row.chomp.split("|")
        country = Country.new
        country.id = id
        country.code = code.downcase
        country.name = name
        country.save
        id = id + 1
      end
    end
  end

  def self.down
    drop_table :countries
  end
end
