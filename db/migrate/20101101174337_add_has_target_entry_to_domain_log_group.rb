class AddHasTargetEntryToDomainLogGroup < ActiveRecord::Migration
  def self.up
    self.connection.execute "TRUNCATE TABLE `domain_log_groups`"
    self.connection.execute "TRUNCATE TABLE `domain_log_stats`"

    create_table :domain_log_sources, :force => true do |t|
      t.string :name
      t.integer :position, :default => 0
      t.boolean :active, :default => 1
      t.string :source_handler
      t.text :options
    end

    add_column :domain_log_groups, :has_target_entry, :boolean, :default => 0

    add_column :domain_log_sessions, :ignore, :boolean, :default => 1
    add_column :domain_log_sessions, :domain_log_source_id, :integer
    add_column :domain_log_sessions, :session_value, :decimal, :precision => 14, :scale => 2, :default => 0.0

    add_column :domain_log_entries, :value, :decimal, :precision => 14, :scale => 2, :default => 0.0

    self.connection.execute "INSERT INTO domain_log_sources (name, position, source_handler, options) VALUES('Affiliate', 1, 'domain_log_source/affiliate', ''), ('Email Campaign', 2, 'domain_log_source/email_campaign', ''), ('Social Network', 3, 'domain_log_source/social_network', ''), ('Search', 4, 'domain_log_source/search', ''), ('Referrer', 5, 'domain_log_source/referrer', ''), ('Type-in', 6, 'domain_log_source/type_in', '')"
  end

  def self.down
    drop_table :domain_log_sources

    remove_column :domain_log_groups, :has_target_entry
    remove_column :domain_log_sessions, :ignore
    remove_column :domain_log_sessions, :domain_log_source_id
    remove_column :domain_log_sessions, :session_value

    remove_column :domain_log_entries, :value
  end
end
