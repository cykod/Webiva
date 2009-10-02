# Copyright (C) 2009 Pascal Rettig.

 class ContentMigrator < ActiveRecord::Migration
 
  def self.update_up(code)
    sing = class << self; self; end
    sing.send :define_method, :up do
      self.module_eval(code)
    end
  end


  def self.migrate_domain(dmn)
    # Do a little connection tomfoolery to
    # get it to migrate on the right db
    
    db_file = YAML.load_file("#{RAILS_ROOT}/config/sites/#{dmn['database']}.yml")
    ActiveRecord::Base.establish_connection(db_file['migrator'])
    DomainModel.establish_connection(db_file['migrator'])
    
    migrate(:up)

    DomainModel.connection.reconnect!
    db_file = YAML.load_file("#{RAILS_ROOT}/config/cms.yml")
    ActiveRecord::Base.establish_connection(db_file[RAILS_ENV])
    ActiveRecord::Base.connection.reconnect!
  end

end
