class AddSiteModuleStatus < ActiveRecord::Migration
  def self.up
    add_column :site_modules, :status, :string, :default => 'inactive'
  end

  def self.down
  end
end
