# Copyright (c) 2008 [Sur http://expressica.com]

class SimpleCaptchaData < DomainModel
  set_table_name "simple_captcha_data"
  
  class << self
    def get_data(key)
      data = find_by_key(key) || new(:key => key)
    end
    
    def remove_data(key)
      clear_old_data
      data = find_by_key(key)
      data.destroy if data
    end
    
    def clear_old_data(time = 1.hour.ago)
      return unless Time === time
      destroy_all("updated_at < '#{time.to_s(:db)}'")
    end
  end
  
end
