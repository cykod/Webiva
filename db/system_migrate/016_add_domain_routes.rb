class AddDomainRoutes < ActiveRecord::Migration
  def self.up
  
    create_table :domain_routes do |t|
      t.integer :domain_id
      t.string :module_name
    end
  end

  def self.down
    drop_table :domain_routes
    
  end
end
