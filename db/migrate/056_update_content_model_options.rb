class UpdateContentModelOptions < ActiveRecord::Migration
  def self.up
    add_column :content_models, :show_on_content, :boolean, :default => false
  end

  def self.down
    remove_column :content_models, :show_on_content
  end
end
