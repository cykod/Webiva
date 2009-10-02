class ContentModelTags < ActiveRecord::Migration
  def self.up

    add_column :content_models, :show_tags, :boolean, :default => false
    add_column :content_model_fields, :show_main_table, :boolean, :default => true
  end

  def self.down
    
    remove_column :content_models, :show_tags
    remove_column :content_model_fields, :show_main_table
  end
end
