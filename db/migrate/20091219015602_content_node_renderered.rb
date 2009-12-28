class ContentNodeRenderered < ActiveRecord::Migration
  def self.up
    create_table :content_node_values do |t|
      t.integer :content_node_id
      t.integer :content_type_id
      t.integer :content_type_id
      t.text :preview
      t.string :title
      t.string :link
      t.string :language, :limit => 10
      t.text :body, :limit => 2.megabytes
      t.timestamps
    end
    
    execute('ALTER TABLE content_node_values ENGINE = MyISAM')
    execute('CREATE FULLTEXT INDEX title_index ON content_node_values (title)')
    execute('CREATE FULLTEXT INDEX body_index ON content_node_values (body,title)')

    change_table :content_types do |t|
      t.remove :detail_site_node_id
      t.string :detail_site_node_url
      t.remove :list_site_node_id
      t.string :list_site_node_url
    end
  end

  def self.down
    drop_table :content_node_values

    change_table :content_types do |t|
      t.integer :detail_site_node_id
      t.remove :detail_site_node_url
      t.integer :list_site_node_id
      t.remove :list_site_node_url
    end
  end
end
