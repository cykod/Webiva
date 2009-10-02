class PageParagraphsAddConnection < ActiveRecord::Migration
  def self.up
  
    add_column :page_paragraphs, :connections, :text
  end

  def self.down
    remove_column :page_paragraphs, :connections
  end
end
