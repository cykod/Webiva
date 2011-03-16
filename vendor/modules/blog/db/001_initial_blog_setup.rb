# Copyright (C) 2009 Pascal Rettig.

class InitialBlogSetup < ActiveRecord::Migration
  def self.up

    # Need to define default weight metric
    create_table :blog_blogs , :force => true do |t|
      t.column :name, :string
      t.column :description, :string
    end

    create_table :blog_post_revisions, :force => true do |t|
      t.column :blog_post_id, :integer
      t.column :title, :string
      t.column :domain_file_id, :integer
      t.column :status, :string, :default => 'active'
      t.column :keywords, :string
      t.column :preview, :text , :limit => 2.megabytes
      t.column :preview_html, :text, :limit => 2.megabytes
      t.column :body, :text , :limit => 2.megabytes

      t.column :body_html, :text , :limit => 2.megabytes
      t.column :author, :string
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :end_user_id, :integer
    end
  

    add_index :blog_post_revisions, :blog_post_id, :name => 'post'

    create_table :blog_posts, :force => true do |t|
      t.column :blog_blog_id, :integer
      t.column :blog_post_revision_id, :integer
      t.column :permalink, :string
      t.column :status, :string, :default => 'draft'
      t.column :disallow_comments, :boolean, :default => false
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :published_at, :datetime
    end

    add_index :blog_posts,[ :blog_blog_id, :created_at ], :name => 'blog'


    create_table :blog_categories, :force => true do |t|
      t.column :blog_blog_id, :integer
      t.column :name, :string
    end
  
    
    add_index :blog_categories,:blog_blog_id, :name => 'blog'

    create_table :blog_posts_categories, :force => true do |t|
      t.column :blog_post_id, :integer
      t.column :blog_category_id, :integer
    end

    add_index :blog_posts_categories, :blog_post_id, :name => 'blog_post'
    add_index :blog_posts_categories, :blog_category_id, :name => 'blog_category_id'

  end

  def self.down
    drop_table :blog_blogs
    drop_table :blog_posts
    drop_table :blog_post_revisions
    drop_table :blog_categories
    drop_table :blog_posts_categories
  end

end
