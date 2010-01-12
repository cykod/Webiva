class Widgets < ActiveRecord::Migration
  def self.up

    create_table :site_widgets do |t|
      t.integer :created_by_id

      t.string :module
      t.string :widget

      t.integer :column, :default => 0
      t.integer :weight, :default => 0

      t.string :title
      t.text :data
      t.boolean :required, :default => false

      t.boolean :view_permission, :default => false
      
      t.timestamps
    end

    create_table :editor_widgets do |t|
      t.integer :site_widget_id
      t.integer :end_user_id

      t.string :title
      t.string :module
      t.string :widget

      t.integer :column, :default => 0
      t.integer :position, :deafult => 0

      t.text :data

      t.boolean :hide, :default => false

      t.timestamps
    end
  end

  def self.down
    drop_table :editor_widgets
    drop_table :site_widgets
  end
end
