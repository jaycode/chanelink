require 'active_record/fixtures'

print "Running db/seeds.rb...\n"

# Do not run if environment is production.
if RAILS_ENV == 'production'
  print "Do not run seeds.rb in production!\n"
else
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
      connection.execute(statement.strip)
    end
  end

  #---------------------------------
  # Other seed data
  #---------------------------------

  # Test members creation
  #---------------------------------
  admin_account = Account.where(:name => 'Plaza Hotel Glodok').first
  property_ids = Property.all(:select => :id, :conditions => {:approved => 1}).collect(&:id)

  super_admin_email = 'jay@chanelink.com'
  super_admin_pass = 'Passw0rd'

  super_admin = Member.create do |m|
    m.name = "Super Admin"
    m.email = super_admin_email
    m.disabled = false
    m.password = super_admin_pass
    m.account = admin_account
    m.assigned_properties = property_ids
    m.master = 1
    m.role = MemberRole.where(:type => 'SuperRole').first
  end

  super_admin.skip_properties_validation = true
  super_admin.update_attributes(:password => super_admin_pass, :prompt_password_change => false)
  #---------------------------------

  # Consult release_notes.md for upgrading migrations.

  print "Seed data imported!\n"
end