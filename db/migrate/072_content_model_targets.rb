class ContentModelTargets < ActiveRecord::Migration
  def self.up

    add_column :content_models, :email_target_connect, :boolean, :default => false
    add_column :content_model_fields, :matched_field, :string

    add_column :content_models, :add_target_tags, :string
    add_column :content_models, :update_target_tags, :string
        
  end

  def self.down
    
    remove_column :content_models, :email_target_connect
    remove_column :content_model_fields, :matched_field
  
    remove_column :content_models, :add_target_tags
    remove_column :content_models, :update_target_tags
  end
end
