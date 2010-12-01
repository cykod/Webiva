class DomainLogEntriesIndexUpdate < ActiveRecord::Migration
  def self.up

    begin
      remove_index :domain_log_entries, :name => 'date_index'
      remove_index :domain_log_entries, :name => 'user_id'
    rescue Exception => e
      # Might not exist
    end

    add_index :domain_log_entries, [ :session_id ], :name => 'session_index'
    add_index :domain_log_entries, [ :occurred_at, :site_node_id ], :name => 'occurred_index'
    add_index :domain_log_entries, [ :user_id, :session_id ], :name => 'user_index'
      
  end

  def self.down
    remove_index :domain_log_entries, :name =>'session_index'
    remove_index :domain_log_entries, :name => 'occurred_index'
    remove_index :domain_log_entries, :name => 'user_index'
    
  end
end
