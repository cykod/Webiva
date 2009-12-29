class ContentMetaTypes < ActiveRecord::Migration
  def self.up

    create_table :content_meta_types do |t|
      t.string :container_type # ForumForum
      t.string :category_field # forum_category_id, for example
      t.text :category_value # 1 or [1, 4, 5]
      
      t.string :paragraph_hash

      t.string :url_field # url 
      
      t.string :detail_url
      t.string :list_url
    end

    add_column :content_types, :content_meta_type_id, :integer
  end

  def self.down
    drop_table :content_meta_types
    remove_column :content_types, :content_meta_type_id
  end
end
