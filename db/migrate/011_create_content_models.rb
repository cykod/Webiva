class CreateContentModels < ActiveRecord::Migration
  def self.up
    create_table :content_models do |t|
      t.column :name, :string
      t.column :table_name, :string
      t.column :description, :string
      t.column :version, :integer
      t.column :options, :text
    end
    
  end

  def self.down
    drop_table :content_models
  end
end
