class UpdateContentPublicationFields < ActiveRecord::Migration
  def self.up
    remove_column :content_publication_fields, :publication_id
    add_column :content_publication_fields, :content_publication_id,:integer
  end

  def self.down
    add_column :content_publication_fields, :publication_id,:integer
    remove_column :content_publication_fields, :content_publication_id
  end
end
