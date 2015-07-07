# class representing a channel
class Channel < ActiveRecord::Base
  DEFAULT_CURRENCY_CODE = 'IDR'

  validates_uniqueness_of :name
  validates_uniqueness_of :type

  # Override in child classes. Setup default values for
  # settings field. These settings are used in Property class.
  def default_settings
  end

  # Room type id used when mapping Channelink room types to OTA's.
  # Override this in child classes when needed.
  # Reference from channel_room_type can be seen from room_type_xml classes
  # e.g. normally RoomTypeXml, for ctrip in class CtripRoomTypeXml.
  # OR RoomTypeChannelMapping
  def room_and_rate_type_id(channel_room_type)
    if channel_room_type.kind_of?(RoomTypeChannelMapping)
      "#{channel_room_type.ota_room_type_id}:#{channel_room_type.ota_rate_type_id}"
    else
      "#{channel_room_type.id}:#{channel_room_type.rate_type_id}"
    end
  end

  # Same as above, but used for name.
  def room_type_name(channel_room_type)
    if channel_room_type.kind_of?(RoomTypeChannelMapping)
      "#{channel_room_type.ota_room_type_name} (#{channel_room_type.ota_rate_type_name}) "+
        "- #{channel_room_type.ota_room_type_id}(#{channel_room_type.ota_rate_type_id})"
    else
      "#{channel_room_type.name} (#{channel_room_type.rate_type_name})"+
        " - #{channel_room_type.id}(#{channel_room_type.rate_type_id})"
    end
  end

  # Proces mapping params before being used as parameter in
  # RoomTypeChannelMapping.new and RoomTypeMasterRateChannelMapping.new
  # override as needed.
  def process_mapping_params(mapping_params)
    mapping_params = ActiveSupport::HashWithIndifferentAccess.new(mapping_params)
    if mapping_params.has_key?(:ota_room_type_id)
      processed = mapping_params[:ota_room_type_id].split(':')
      if processed.count == 2
        mapping_params[:ota_room_type_id] = processed[0]
        mapping_params[:ota_rate_type_id] = processed[1]
      end
    end
    mapping_params
  end

  # Get all channels.
  # self.descendants is already used in ActiveRecord::Base, and using that
  # would break [something]Channel.first
  def self.descendants_without_loading
    Dir[Rails.root + 'app/models/channels/*.rb'].map {|f| File.basename(f, '.*').camelize.constantize}
  end

  def cname
    # to be override by child class
  end

  # equality for channel
  def ==(other)
    return self.id == other.id
  end

  # get rate multiplier for given property on this channel
  def rate_multiplier(property)
    result = 1.0
    pc = PropertyChannel.find_by_property_id_and_channel_id(property.id, self.id)
    if !pc.blank?
      result = pc.rate_conversion_multiplier if !pc.rate_conversion_multiplier.blank? and pc.rate_conversion_multiplier > 0
    end
    result
  end

  # get currency converter for given property on this channel
  def currency_converter(property)
    result = 1.0
    pc = PropertyChannel.find_by_property_id_and_channel_id(property.id, self.id)
    if property.currency_conversion_enabled? and !pc.blank? and !pc.currency_conversion.blank?
      result = pc.currency_conversion.multiplier 
    end
    result
  end

  # return list of channel not registered yet
  def self.select_list(current_property)
    result = Array.new
    result << [I18n.t('channels.placeholder'), nil]
    Channel.order(:name).each do |channel|
      # do not include channel that already been registered for the property
      result << [channel.name, channel.id] if PropertyChannel.find_by_channel_id_and_property_id(channel.id, current_property.id).blank?
    end
    result
  end

  # return list of channel by property and pool
  def self.list_by_property_and_pool(current_property, pool)
    result = Array.new
    result << [I18n.t('reports.channel_trends.channels.all'), nil]

    scope = PropertyChannel.scoped({})
    scope = scope.where(:property_id => current_property.id)
    scope = scope.where(:pool_id => pool.id) if !pool.blank?
    scope = scope.order(:channel_id)

    scope.each do |pc|
      # do not include channel that already been registered for the property
      result << [pc.channel.name, pc.channel.id]
    end
    result
  end

  # return list of channel by property and pool, without all selection
  def self.list_by_property_and_pool_without_all(current_property, pool, restriction)
    result = Array.new

    scope = PropertyChannel.scoped({})
    scope = scope.where(:property_id => current_property.id)
    scope = scope.where(:pool_id => pool.id) if !pool.blank?
    scope = scope.order(:channel_id)

    puts restriction

    scope.each do |pc|
      # do not include channel that already been registered for the property
      if !restriction.blank?
        puts 'here1'
        result << [pc.channel.name, pc.channel.id] if restriction.include?(pc.channel.id)
      else
        puts 'here2'
        result << [pc.channel.name, pc.channel.id]
      end
    end
    result
  end

end
