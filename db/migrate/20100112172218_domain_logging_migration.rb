
class DomainLoggingMigration < ActiveRecord::Migration
  def self.up
    execute 'TRUNCATE domain_log_entries'
    execute 'TRUNCATE domain_log_sessions'

    remove_index :domain_log_entries, :name => :session_index

    remove_column :domain_log_entries, :ip_address
    remove_column :domain_log_entries, :session_id
    remove_column :domain_log_entries, :status
    remove_column :domain_log_entries, :paction

    add_column :domain_log_entries, :domain_log_session_id, :integer
    add_column :domain_log_entries, :http_status, :integer

    add_index :domain_log_entries, :domain_log_session_id, :name => :domain_log_session_id_idx

    add_column :domain_log_sessions, :affiliate, :string
    add_column :domain_log_sessions, :campaign, :string
    add_column :domain_log_sessions, :origin, :string
    add_column :domain_log_sessions, :affiliate_data, :string
    add_column :domain_log_sessions, :referrer_domain, :string
    add_column :domain_log_sessions, :referrer_path, :string
  end
    
  def self.down
    execute 'TRUNCATE domain_log_entries'
    execute 'TRUNCATE domain_log_sessions'

    remove_index :domain_log_entries, :name => :domain_log_session_id_idx

    remove_column :domain_log_entries, :domain_log_session_id
    remove_column :domain_log_entries, :http_status

    add_column :domain_log_entries, :ip_address, :string
    add_column :domain_log_entries, :session_id, :string
    add_column :domain_log_entries, :status, :string
    add_column :domain_log_entries, :paction, :string

    add_column :domain_log_entries, :session_id, :name => :session_index

    remove_column :domain_log_sessions, :affiliate
    remove_column :domain_log_sessions, :campaign
    remove_column :domain_log_sessions, :origin
    remove_column :domain_log_sessions, :affiliate_data
    remove_column :domain_log_sessions, :referrer_domain
    remove_column :domain_log_sessions, :referrer_path
  end
end
