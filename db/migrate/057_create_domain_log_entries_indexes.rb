class CreateDomainLogEntriesIndexes < ActiveRecord::Migration
  def self.up
    change_column :domain_log_entries,:occurred_at, :datetime

    add_index :domain_log_entries, [ :session_id, :occurred_at ], :name => 'date_index'
    add_index :domain_log_entries, [ :user_id, :occurred_at, :session_id  ], :name => 'user_id'
  end

  def self.down
    remove_index :domain_log_entries, :name => 'date_index'
    remove_index :domain_log_entries, :name => 'user_id'
  end
end
