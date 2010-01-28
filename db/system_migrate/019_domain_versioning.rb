class DomainVersioning < ActiveRecord::Migration
  def self.up
    add_column :domains, :created_at, :datetime
    add_column :domains, :updated_at, :datetime
    add_column :domains, :iteration, :integer,:default => 0
  end

  def self.down
    remove_column :domains, :created_at
    remove_column :domains, :updated_at
    remove_column :domains, :iteration
  end
end
