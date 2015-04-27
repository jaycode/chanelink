# Some methods for a model's settings field.
module HasSettings
  # Getter. *params is parameters in hierarchial order,
  # e.g. settings(:ota, :username) will get {:ota => {:username => 'this value'}}.
  # If no params given, give the json decoded settings
  def settings(*params)
    obj = JSON.parse(read_attribute(:settings))
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
    if params.class == Hash # this also covers not nil.
      settings_json = settings.merge(params)
      write_attribute(:settings, ActiveSupport::JSON.encode(settings_json))
    end
  end

  def destroy_settings
    write_attribute(:settings, ActiveSupport::JSON.encode({}))
  end
end