# class represent booking status
class BookingStatus < ActiveRecord::Base

  NEW = 'new'
  MODIFY = 'modify'
  CANCEL = 'cancel'

  def self.new_type
    BookingStatus.find_by_name(NEW)
  end

  def self.modify_type
    BookingStatus.find_by_name(MODIFY)
  end

  def self.cancel_type
    BookingStatus.find_by_name(CANCEL)
  end
  
end
