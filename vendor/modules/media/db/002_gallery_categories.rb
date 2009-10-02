# Copyright (C) 2009 Pascal Rettig.

class GalleryCategories < ActiveRecord::Migration
  def self.up
    add_column :galleries, :category, :string
    
    add_index :galleries, [:container_type,:container_id],:name => 'container_index'
    
    add_column :gallery_images, :approved, :boolean, :default => true
  end

  def self.down
    remove_column :galleries, :category
    remove_index :galleries, :name => 'container_index'
    remove_column :gallery_images, :approved
  end
end
