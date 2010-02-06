
if Rails.env == 'test'
    if defaults_config_file['testing_domain']
      ActiveRecord::Base.establish_connection(YAML.load_file("#{RAILS_ROOT}/config/cms.yml")['test'])
      SystemModel.establish_connection(YAML.load_file("#{RAILS_ROOT}/config/cms.yml")['test'])
      DomainModel.activate_domain(Domain.find(defaults_config_file['testing_domain']).attributes,'production',false)
    else
      raise 'No Available Testing Database!'
    end
end 
if Rails.env == 'cucumber' || Rails.env == 'selenium'
    if defaults_config_file['cucumber_domain']
      ActiveRecord::Base.establish_connection(YAML.load_file("#{RAILS_ROOT}/config/cms.yml")['cucumber'])
      SystemModel.establish_connection(YAML.load_file("#{RAILS_ROOT}/config/cms.yml")['cucumber'])
      dmn = Domain.find(defaults_config_file['cucumber_domain']).attributes
      DomainModel.activate_domain(dmn,'production',false)
    else
      raise 'No Available Cucumber Database!'
    end
end
