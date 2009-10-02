
class TriggeredActionsMigration < ActiveRecord::Migration
  def self.up
    add_column :triggered_actions, :action_module, :string, :default => 'trigger/core_trigger'
  end

  def self.down
    remove_column :triggered_actions, :action_module
  end  
end


