# Copyright (C) 2009 Pascal Rettig.

class MediaSetup < ActiveRecord::Migration
  def self.up
    create_table :galleries do |t|
      t.column :name, :string
      t.column :private_gallery, :boolean, :default => false
      t.column :container_type, :string
      t.column :container_id, :integer
      t.column :domain_file_id, :integer
      t.column :owner_type, :string
      t.column :owner_id, :integer
      t.column :description, :text
      t.column :occurred_at, :datetime
      t.column :image_count, :integer, :default => 0
    end
    
    create_table :gallery_tags, :id => false do |t|
      t.column :tag_id, :integer, :null => false
      t.column :gallery_id, :integer, :null => false
    end
    
    create_table :gallery_images do |t|
      t.column :gallery_id, :integer, :null => false
      t.column :domain_file_id, :integer, :null => false
      t.column :position, :integer
      t.column :name, :string
    end
  end

  def self.down
    drop_table :galleries
    drop_table :gallery_tags
    drop_table :gallery_images
  end
end
