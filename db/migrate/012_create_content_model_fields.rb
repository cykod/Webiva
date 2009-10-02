class CreateContentModelFields < ActiveRecord::Migration
  def self.up
    create_table :content_model_fields do |t|
      t.column :name, :string
      t.column :content_model_id, :integer
      t.column :description, :text
      t.column :field, :string
      t.column :field_type, :string
      t.column :field_options, :text
      t.column :position,:integer
      
    end
  end

  def self.down
    drop_table :content_model_fields
  end
end
