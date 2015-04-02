class ZeroInventoryAlert < Alert

  # to render this alert in view
  def to_display
    inventory = Inventory.find(self.data_id)
    I18n.t('alerts.display.zero_inventory_alert', :pool => inventory.pool.name, :room_type => inventory.room_type.name, :date => DateUtils.date_to_key(inventory.date))
  end
  
  # create this alert for a property
  def self.create_for_property(inventory, property)
    property.members.each do |member|
      ZeroInventoryAlert.create(:receiver_id => member.id, :property_id => property.id, :data_id => inventory.id)
    end
  end

  # send email for this alert
  def send_email
    AlertNotifier.delay.email_zero_inventory(self)
  end
  
  def property
    Inventory.find(self.data_id).property
  end

end