
class AddBuiltIn < ActiveRecord::Migration

  def self.up
    add_column :globalize_translations, :built_in, :boolean, :default => 0
    
  end  
  
  def self.down
    remove_column :globalize_translations,:built_in 
  end
end
