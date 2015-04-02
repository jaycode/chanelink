require 'singleton'

# class to retrieve channel room types
class RoomTypeFetcher
  include Singleton

  def retrieve
    # do nothing, to be implemented by sub class
  end

end