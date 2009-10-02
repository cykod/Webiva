class DropAccessGroups < ActiveRecord::Migration
  def self.up
    begin
      drop_table :access_groups
      drop_table :access_hierarchies
      drop_table :blog_entries
    rescue Exception => e
      
    end
  end

  def self.down
  end
end
