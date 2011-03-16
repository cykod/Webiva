class DomainLogEngines < ActiveRecord::Migration
  def self.up
    self.connection.execute "ALTER TABLE `domain_log_entries` ENGINE=MYISAM"
    self.connection.execute "ALTER TABLE `domain_log_sessions` ENGINE=MYISAM"
    self.connection.execute "ALTER TABLE `domain_log_visitors` ENGINE=MYISAM"
  end

  def self.down
    self.connection.execute "ALTER TABLE `domain_log_entries` ENGINE=INNODB"
    self.connection.execute "ALTER TABLE `domain_log_sessions` ENGINE=INNODB"
    self.connection.execute "ALTER TABLE `domain_log_visitors` ENGINE=INNODB"
  end
end
