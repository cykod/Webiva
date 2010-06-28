class AddContentModelToBlog < ActiveRecord::Migration
  def self.up
    add_column :blog_blogs, :content_model_id, :integer
    add_column :blog_blogs, :content_publication_id, :integer
    add_column :blog_posts, :data_model_id, :integer
  end

  def self.down
    remove_column :blog_blogs, :content_model_id
    remove_column :blog_blogs, :content_publication_id
    remove_column :blog_posts, :data_model_id
  end
end
