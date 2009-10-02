class AccessTokenUpdate < ActiveRecord::Migration
  def self.up
    add_column :access_tokens, :description, :string

    create_table :tag_notes do |t|
      t.integer :tag_id
      t.text :description
      t.text :notes
    end


    add_column :content_models, :view_access_control, :boolean, :default => false
    add_column :content_models, :edit_access_control, :boolean, :default => false
  end

  def self.down

    remove_column :access_tokens, :description

    drop_table :tag_notes

    remove_column :content_models, :view_access_control
    remove_column :content_models, :edit_access_control
    
  end
end
