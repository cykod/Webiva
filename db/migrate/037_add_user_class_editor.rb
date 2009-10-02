class AddUserClassEditor < ActiveRecord::Migration
  def self.up
    add_column :user_classes, :editor, :boolean, :default => false
  end

  def self.down
    remove_column :user_classes, :editor
  end
end
