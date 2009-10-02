
class CreateDomainModulesTable < ActiveRecord::Migration

  def self.up
    create_table "domain_modules", :force => true do |t|
      t.column "name", :string
      t.column "domain_id", :integer
      t.column "access", :string
    end
      
  end  
  
  def self.down
    
  end
end
