# Some methods for a model's settings field.
module HasSettings
  # Getter. *params is parameters in hierarchial order,
  # e.g. settings(:ota, :username) will get {:ota => {:username => 'this value'}}.
  # If no params given, give the json decoded settings
  def settings(*params)
    settings_json = read_attribute(:settings)
    if settings_json.nil?
      settings_json = '{}'
    end
    obj = JSON.parse(settings_json)
    if params.empty?
      obj
    else
      params.each do |p|
        if defined? obj[p.to_s]
          obj = obj[p.to_s]
        else
          obj = nil
        end
      end
      obj
    end
  end

  # Setter. Simply merge with given params. See property_channel_test for sample
  # test case.
  def settings=(params)
    # HashWithIndifferentAccess is created when settings field was made from update_attributes
    if params.class == String
      begin
        params = JSON.parse(params)
      rescue Exception => e
        # do nothing
      end
    end
    if params.class == Hash or params.class == ActiveSupport::HashWithIndifferentAccess # this also covers not nil.
      settings_hash = settings.merge(params)
      write_attribute(:settings, ActiveSupport::JSON.encode(settings_hash))
    end
  end

  def destroy_settings
    write_attribute(:settings, ActiveSupport::JSON.encode({}))
  end

  def update_empty_settings(params)
    if settings.blank?
      settings_json = {}
    else
      settings_json = settings
    end
    if params.class == String
      begin
        params = JSON.parse(params)
      rescue Exception => e
        # do nothing
      end
    end
    if params.class == Hash or params.class == ActiveSupport::HashWithIndifferentAccess
      params.each do |k, v|
        if !defined?(settings_json[k.to_s]) or settings_json[k.to_s].blank?
          settings_json[k.to_s] = v.to_s
        end
      end
    end
    write_attribute(:settings, ActiveSupport::JSON.encode(settings_json))
  end
end