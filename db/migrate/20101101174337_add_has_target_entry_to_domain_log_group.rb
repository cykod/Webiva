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

    add_column :domain_log_stats, :total_value, :decimal, :precision => 14, :scale => 2, :default => 0.0

    add_column :end_users, :value, :decimal, :precision => 14, :scale => 2, :default => 0.0

    self.connection.execute "INSERT INTO domain_log_sources (name, position, source_handler, options) VALUES('Affiliate', 1, 'domain_log_source/affiliate', ''), ('Email Campaign', 2, 'domain_log_source/email_campaign', ''), ('Social Network', 3, 'domain_log_source/social_network', ''), ('Search', 4, 'domain_log_source/search', ''), ('Referrer', 5, 'domain_log_source/referrer', ''), ('Type-in', 6, 'domain_log_source/type_in', '')"

    # Update session sources

    # affiliate
    self.connection.execute 'UPDATE domain_log_sessions SET domain_log_source_id = 1, `ignore` = 0 WHERE affiliate IS NOT NULL AND affiliate != "" AND domain_log_source_id IS NULL'

    # email campaign
    result = self.connection.execute "show tables like 'market_campaign_queue_sessions'"
    self.connection.execute 'UPDATE domain_log_sessions, market_campaign_queue_sessions SET domain_log_source_id = 2, `ignore` = 0 WHERE domain_log_sessions.session_id = market_campaign_queue_sessions.session_id AND domain_log_source_id IS NULL' if result.num_rows > 0

    # search
    self.connection.execute 'UPDATE domain_log_sessions SET domain_log_source_id = 4, `ignore` = 0 WHERE `query` IS NOT NULL AND `query` != "" AND domain_log_source_id IS NULL'

    # referrer
    self.connection.execute 'UPDATE domain_log_sessions SET domain_log_source_id = 5, `ignore` = 0 WHERE domain_log_referrer_id > 0 AND domain_log_referrer_id IS NOT NULL AND domain_log_source_id IS NULL'

    # type-in
    self.connection.execute 'UPDATE domain_log_sessions SET domain_log_source_id = 6, `ignore` = 0 WHERE domain_log_source_id IS NULL'

    # ignore client users
    self.connection.execute 'UPDATE domain_log_sessions, end_users SET `ignore` = 1 WHERE end_user_id IS NOT NULL AND end_user_id = end_users.id AND end_users.client_user_id IS NOT NULL'

    # ignore visitors that do not have a country
    self.connection.execute 'UPDATE domain_log_sessions, domain_log_visitors SET `ignore` = 1 WHERE domain_log_visitor_id IS NOT NULL AND domain_log_visitor_id = domain_log_visitors.id AND domain_log_visitors.country IS NULL'
  end

  def self.down
    drop_table :domain_log_sources

    remove_column :domain_log_groups, :has_target_entry
    remove_column :domain_log_sessions, :ignore
    remove_column :domain_log_sessions, :domain_log_source_id
    remove_column :domain_log_sessions, :session_value

    remove_column :domain_log_entries, :value

    remove_column :domain_log_stats, :total_value

    remove_column :end_users, :value
  end
end
