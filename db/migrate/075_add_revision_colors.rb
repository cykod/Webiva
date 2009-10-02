class AddRevisionColors < ActiveRecord::Migration
  def self.up

    add_column :page_revisions, :color, :string
    add_column :page_revisions, :color_selected, :string
    add_column :page_revisions, :color_hover, :string

    add_column :page_revisions, :field1, :string
    add_column :page_revisions, :field2, :string
    
  end

  def self.down
    
    remove_column :page_revisions, :color
    remove_column :page_revisions, :color_selected
    remove_column :page_revisions, :color_hover
    
    remove_column :page_revisions, :field1
    remove_column :page_revisions, :field2
    
  end
end
