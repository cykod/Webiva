class CreateContentPublicationFields < ActiveRecord::Migration
  def self.up
    create_table :content_publication_fields do |t|
      t.column :publication_id, :integer
      t.column :content_model_field_id, :integer
      t.column :label, :string
      t.column :field_type, :string
      t.column :data, :text
      t.column :position, :integer
    end
  end

  def self.down
    drop_table :content_publication_fields
  end
end
