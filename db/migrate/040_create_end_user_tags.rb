class CreateEndUserTags < ActiveRecord::Migration
  def self.up
    create_table :end_user_tags, :id => false do |t|
      t.column :tag_id, :integer, :null => false
      t.column :end_user_id, :integer, :null => false
    end
  end

  def self.down
  end
end
