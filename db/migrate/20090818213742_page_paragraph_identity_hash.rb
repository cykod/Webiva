class PageParagraphIdentityHash < ActiveRecord::Migration
  def self.up

    add_column :page_paragraphs, :identity_hash, :string

    add_column :site_nodes, :lft, :integer
    add_column :site_nodes, :rgt, :integer

    remove_column :site_nodes, :children_count

    create_table :site_versions, :force => true do |t|
      t.string :name
      t.boolean :default_version, :default => false
    end

    add_column :site_nodes, :site_version_id, :integer,  :default => 1

    execute "INSERT INTO site_versions (id,name,default_version) VALUES (1,'Default',1)"
    execute "UPDATE page_paragraphs SET identity_hash = id WHERE 1"
  end

  def self.down

    remove_column :page_paragraphs, :identity_hash

    remove_column :site_nodes, :lft
    remove_column :site_nodes, :rgt

    add_column :site_nodes, :children_count, :integer

    drop_table :site_versions

    remove_column :site_nodes, :site_version_id
  end
end
