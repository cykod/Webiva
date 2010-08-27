class StatsTables < ActiveRecord::Migration
  def self.up
    create_table :domain_log_groups do |t|
      t.string :target_type
      t.integer :target_id
      t.string :stat_type
      t.datetime :started_at
      t.integer :duration
      t.datetime :expires_at
    end

    add_index :domain_log_groups, [:target_type, :started_at, :duration], :name => 'domain_log_groups_idx'

    create_table :domain_log_stats do |t|
      t.integer :domain_log_group_id
      t.integer :target_id
      t.integer :visits
      t.integer :hits
      t.integer :leads
      t.integer :conversions
      t.integer :stat1
      t.integer :stat2
    end

    add_index :domain_log_stats, [:domain_log_group_id, :target_id], :name => 'domain_log_stats_idx'
  end

  def self.down
    drop_table :domain_log_groups
    drop_table :domain_log_stats
  end
end


