class AddHasTargetEntryToDomainLogGroup < ActiveRecord::Migration
  def self.up
    self.connection.execute "TRUNCATE TABLE `domain_log_groups`"
    self.connection.execute "TRUNCATE TABLE `domain_log_stats`"

    add_column :domain_log_groups, :has_target_entry, :boolean
  end

  def self.down
    remove_column :domain_log_groups, :has_target_entry
  end
end
