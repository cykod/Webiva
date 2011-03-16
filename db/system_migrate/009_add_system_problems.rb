class AddSystemProblems < ActiveRecord::Migration
  def self.up
    create_table "system_issues", :force => true do |t|
      t.column :reported_at, :datetime
      t.column :reporting_domain, :string, :limit => 80
      
      t.column :reporter_user_type, :string
      t.column :reporter_user_id, :integer
      t.column :reported_type, :string, :default => 'auto'
      
      t.column :status, :string, :default => 'reported'
      t.column :estimate, :decimal, :default => 0.0, :precision => 5, :scale => 2
      t.column :time_log, :decimal, :default => 0.0, :precision => 5, :scale => 2
      t.column :completed_percentage, :integer, :default => 0
      
      t.column :updated_at, :datetime
      
      t.column :reproducible, :boolean, :default => false
      
      t.column :location, :string, :limit => 160
      t.column :behavior, :text
      t.column :expected_behavior, :text
    end
    
    add_index(:system_issues, [ :reporting_domain, :location, :reported_at ], :name => 'dmn_loc_rep_index')
    
    create_table "system_issue_notes", :force => true do |t|
      t.column :system_issue_id, :integer
      t.column :entered_at,:datetime
      t.column :work_time, :decimal, :default => 0.0, :precision => 5, :scale => 2
      t.column :action, :string
      
      t.column :domain_file_id, :integer
      
      t.column :note, :text
      t.column :entered_user_type, :string
      t.column :entered_user_id, :integer
    end
    
    add_index(:system_issue_notes, [ :system_issue_id, :entered_at ], :name => 'problem_entered_on')
  end

  def self.down
  end
end
