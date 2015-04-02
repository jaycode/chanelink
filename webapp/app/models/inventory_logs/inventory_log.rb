# represent every change to an inventory, basically version tracker
class InventoryLog < ActiveRecord::Base

  belongs_to :inventory
  
end
