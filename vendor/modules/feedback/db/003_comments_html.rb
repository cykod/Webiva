
class CommentsHtml < ActiveRecord::Migration
  def self.up
    add_column :comments, :comment_html, :text
  end

  def self.down
    remove_column :comments, :comment_html
  end
end
