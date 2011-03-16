class InitialSimpleContentSetup < ActiveRecord::Migration
  def self.up
    create_table :simple_content_models, :force => true do |t|
      t.string :name
      t.text :fields, :limit => 16777215
      t.timestamps
    end
  end

  def self.down
    drop_table :simple_content_models
  end
end
