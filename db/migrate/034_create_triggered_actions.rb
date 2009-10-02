class CreateTriggeredActions < ActiveRecord::Migration
  def self.up
    create_table :triggered_actions do |t|
     t.column :name, :string
     t.column :action_type, :string
     t.column :action_trigger, :string
     t.column :trigger_type, :string
     t.column :trigger_id, :integer
     t.column :data, :text 
     t.column :created_at, :datetime
     t.column :comitted, :boolean, :default => false
    end
  end

  def self.down
    drop_table :triggered_actions
  end
end
