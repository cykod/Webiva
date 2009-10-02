
class DropDomainModulesTable < ActiveRecord::Migration

  def self.up
    drop_table :domain_modules
  end  
  
  def self.down
    
  end
end
