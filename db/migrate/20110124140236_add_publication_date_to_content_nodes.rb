class AddPublicationDateToContentNodes < ActiveRecord::Migration
  def self.up
    add_column :content_nodes, :published_at, :datetime
  end

  def self.down
    remove_column :content_nodes, :published_at
  end
end
