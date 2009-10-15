class ContentModelRelation < ActiveRecord::Migration
  def self.up

    create_table :content_relations do |t|
      t.integer :content_model_id
      t.integer :content_model_field_id
      t.string :entry_type,:limit => 32
      t.integer :entry_id
      t.string :relation_type,:limit => 32
      t.integer :relation_id
    end

    add_index :content_relations, [ :content_model_id, :content_model_field_id, :entry_id ], :name => 'entry_index'

    add_column :content_models, :identifier_name, :string

  end

  def self.down
    drop_table :content_relations
    remove_column :content_models, :identifier_name
  end
end
