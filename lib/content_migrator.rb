# Copyright (C) 2009 Pascal Rettig.

class ContentMigrator < ActiveRecord::Migration

  module MigratorExtension
    def connection
      DomainModel.connection
    end


    def migrate_domain(dmn)
      if dmn.is_a?(Domain)
        dmn = dmn.get_info
      else
        domain = Domain.find(dmn['id'])
        dmn = domain.get_info
      end

      # Get us the migrator DB
      DomainModel.activate_database(dmn,'migrator',false)
      migrate(:up)
    end
  end

 
  def self.update_up(code)
    define_singleton_method :up do 
      self.module_eval(code)
    end
    self.extend(ContentMigrator::MigratorExtension)
  end

end
