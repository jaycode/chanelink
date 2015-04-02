# represent every change to an inventory caused by a booking, basically version tracker
class BookingInventoryLog < InventoryLog

  belongs_to :booking
  
end
