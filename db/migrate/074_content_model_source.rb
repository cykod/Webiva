class ContentModelSource < ActiveRecord::Migration
  def self.up

    add_column :content_models, :add_target_source, :string
  end

  def self.down
    
    remove_column :content_models, :add_target_source
  end
end
