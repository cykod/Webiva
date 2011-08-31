class AddWebformExperiment < ActiveRecord::Migration
  def self.up
    add_column :experiments, :data, :text
  end

  def self.down
    drop_column :experiments, :data
  end
end
