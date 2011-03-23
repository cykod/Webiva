Webiva::Application.configure do
  if Rails.env == 'test'
    testing_domain = config.webiva_defaults['testing_domain']
    raise 'No Available Testing Database!' unless testing_domain

    db_info = YAML.load_file("#{Rails.root}/config/cms.yml")['test']
    ActiveRecord::Base.establish_connection db_info
    SystemModel.establish_connection db_info
    DomainModel.activate_domain(Domain.find(testing_domain).get_info, 'migrator', false)
  end
end
