
class ContentFilters < ActiveRecord::Migration
  def self.up
    create_table :content_filters do |t|
      t.string :name
      t.string :identifier
      t.text :description
      t.text :filters
      t.text :options
      t.boolean :active,:default => false
    end

  end

  def self.down
    drop_table :content_filters
  end  
end


