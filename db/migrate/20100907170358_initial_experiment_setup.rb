class InitialExperimentSetup < ActiveRecord::Migration
  def self.up
    create_table :experiments do |t|
      t.string :name
      t.string :experiment_container_type
      t.integer :experiment_container_id
      t.datetime :started_at
      t.datetime :ended_at
      t.text :note
      t.integer :conversion_site_node_id
      t.timestamps
    end

    create_table :experiment_versions do |t|
      t.integer :experiment_id
      t.string :language
      t.decimal "revision", :limit => 8, :precision => 8, :scale => 2, :default => 0.0
      t.integer :weight
    end

    create_table :experiment_users do |t|
      t.integer :domain_log_visitor_id
      t.integer :domain_log_session_id
      t.integer :experiment_version_id
      t.integer :experiment_id
      t.string :language
      t.integer :end_user_id
      t.timestamps
      t.boolean :success, :default => 0
    end

    add_column :site_nodes, :experiment_id, :integer
    add_column :page_revisions, :version_name, :string
  end

  def self.down
    drop_table :experiments
    drop_table :experiment_versions
    drop_table :experiment_users

    remove_column :site_nodes, :experiment_id
    remove_column :page_revisions, :version_name
  end
end
