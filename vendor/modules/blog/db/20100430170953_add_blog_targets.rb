class AddBlogTargets < ActiveRecord::Migration
  def self.up
    create_table :blog_targets do |t|
      t.string :target_type
      t.integer :content_type_id
    end

    add_column :blog_blogs, :blog_target_id, :integer
    
  end

  def self.down
    drop_table :blog_targets
    remove_column :blog_blogs, :blog_target_id
  end
end
