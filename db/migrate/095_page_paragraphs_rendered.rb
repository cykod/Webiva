
class PageParagraphsRendered < ActiveRecord::Migration
  def self.up
    add_column :page_paragraphs, :display_body_html, :text  
  end

  def self.down 
    remove_column :page_paragraphs, :display_body_html

  end
end
