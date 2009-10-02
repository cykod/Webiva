class AddDomainLogPActionData < ActiveRecord::Migration
  def self.up
    add_column :domain_log_entries, :paction_data, :string
  end

  def self.down
    remove_column :domain_log_entries,:paction_data
  end
end
