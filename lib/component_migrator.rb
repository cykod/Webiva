# Copyright (C) 2009 Pascal Rettig.

class ComponentMigrator < ActiveRecord::Migrator  # :nodoc:all

   cattr_accessor :current_component

   def self.schema_migrations_table_name
     'component_schemas'
   end

   def self.current_version
     result = DomainModel.connection.select_one("SELECT version FROM #{schema_migrations_table_name} WHERE component = #{DomainModel.connection.quote(current_component)} ORDER BY CONVERT(version,unsigned) DESC")
     if result
      result['version'].to_i
     else
      0
     end
   end
   
  
   def self.get_all_versions
      DomainModel.connection.select_values("SELECT version FROM #{schema_migrations_table_name} WHERE component = #{DomainModel.connection.quote(current_component)}").map(&:to_i).sort
   end



   # Migrate the component schemas table from the old to the new migrations version
   def self.handle_migration_update
    result = DomainModel.connection.select_one("SELECT version FROM #{schema_migrations_table_name} WHERE component = 'migration_update'")
    if !result
      DomainModel.connection.execute("ALTER TABLE #{schema_migrations_table_name} CHANGE `version` `version` VARCHAR( 255 ) NULL DEFAULT '0'")
      DomainModel.connection.execute("INSERT INTO #{schema_migrations_table_name} (version, component) VALUES (1,'migration_update')")
      components = DomainModel.connection.select_all("SELECT * FROM #{schema_migrations_table_name}")
      components.each do |comp|
        (1..(comp['version'].to_i-1)).each do |version|
           DomainModel.connection.execute("INSERT  INTO #{schema_migrations_table_name} (version, component) VALUES (#{version},#{DomainModel.connection.quote(comp['component'])})")
        end
      end
    end
   
   end

   private
   
   def record_version_state_after_migrating(version)
        sm_table = self.class.schema_migrations_table_name

        @migrated_versions ||= []
        if down?
          @migrated_versions.delete(version.to_i)
         DomainModel.connection.update("DELETE FROM #{sm_table} WHERE version = '#{version}' AND component = #{DomainModel.connection.quote(current_component)}")
        else
          @migrated_versions.push(version.to_i).sort!
          DomainModel.connection.insert("INSERT INTO #{sm_table} (component,version) VALUES ( #{DomainModel.connection.quote(current_component)}, '#{version}')")
        end
      end
   
end
