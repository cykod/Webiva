class AddSessionIdIndex < ActiveRecord::Migration
  def self.up
    change_column :domain_log_sessions, :session_id, :string, :limit => 32

    execute("CREATE INDEX session_index ON domain_log_sessions (session_id(10))")
  end

  def self.down
    execute("DROP INDEX session_index ON domain_log_sessions")
  end
end
