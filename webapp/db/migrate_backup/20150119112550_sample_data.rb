class SampleData < ActiveRecord::Migration
  def self.up

    account = Account.create(:contact_name => 'Chanelink', :contact_email => 'admin@chanelink.com', :approved => 1)
    account = Account.create(:name => 'Chanelink', :contact_name => 'Chanelink', :contact_email => 'admin@chanelink.com', :address => 'no address for this account', :approved => 1, :telephone => '123123')
  	User.create(:name => 'Admin', :email => 'admin@chanelink.com', :password => 'chanelink', :super => 1)
    Member.create(:name => 'Admin', :email => 'admin@chanelink.com', :password => 'chanelink', :account_id => account.id)

  	AgodaChannel.create(:name => 'Agoda')
    ExpediaChannel.create(:name => 'Expedia')
    BookingcomChannel.create(:name => 'Booking.com')

    BookingStatus.create(:name => 'new')
    BookingStatus.create(:name => 'cancel')
    BookingStatus.create(:name => 'modify')

    Configuration.create(:days_to_keep_cc_info => 7)

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
    # To remove tables, do the following commands:
    # rake db:drop RAILS_ENV=staging2
    # rake db:create RAILS_ENV=staging2
  end
end