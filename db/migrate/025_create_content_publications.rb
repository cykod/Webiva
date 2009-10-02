class CreateContentPublications < ActiveRecord::Migration
  def self.up
    create_table :content_publications do |t|
      t.column :name,:string
      t.column :publication_type, :string
      t.column :feature_name, :string
      t.column :content_model_id, :integer
      t.column :description, :text
      t.column :data, :text
      t.column :actions, :text
    end
  end

  def self.down
    drop_table :content_publications
  end
end
