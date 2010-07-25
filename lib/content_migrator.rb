# Copyright (C) 2009 Pascal Rettig.

 class ContentMigrator < ActiveRecord::Migration
 
  def self.update_up(code)
    sing = class << self; self; end
    sing.send :define_method, :up do
      self.module_eval(code)
    end
  end

 def self.connection
   DomainModel.connection
 end


  def self.migrate_domain(dmn)
    domain = Domain.find(dmn['id'])
    dmn = domain.get_info

    # Get us the migrator DB
    DomainModel.establish_connection(dmn[:domain_database][:options]['migrator'])
    migrate(:up)
  end

end
