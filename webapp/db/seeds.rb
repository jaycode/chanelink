require 'active_record/fixtures'

print "Running db/seeds.rb...\n"

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

connection = ActiveRecord::Base.connection
connection.tables.each do |table|
connection.execute("TRUNCATE #{table}") unless table == "schema_migrations"
end

# - IMPORTANT: SEED DATA ONLY
# - DO NOT EXPORT TABLE STRUCTURES
# - DO NOT EXPORT DATA FROM `schema_migrations`
print "Importing from db/seeds.sql...\n"
sql = File.read("#{Rails.root}/db/seeds.sql")
statements = sql.split(/;/)
print "Found #{statements.count} queries.\n"
statements.pop  # the last empty statement

ActiveRecord::Base.transaction do
    statements.each do |statement|
        # print "#{statement.strip}\n"
        connection.execute(statement.strip)
    end
end

# Other seed data

super_admin = Member.create

print "Seed data imported!\n"