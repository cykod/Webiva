class AddPageParagraphPublicationId < ActiveRecord::Migration
  def self.up
    add_column :page_paragraphs, :content_publication_id, :integer
  end

  def self.down
    remove_column :page_paragraphsm, :content_publication_id, :integer
  end
end
