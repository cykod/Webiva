class ContentSearchable < ActiveRecord::Migration
  def self.up
    change_table :content_types do |t|
      t.boolean :protected_results, :default => false
    end

    change_table :content_node_values do |t|
      t.boolean :search_result, :default => true
      t.boolean :protected_result, :default => false
    end
  end

  def self.down
    change_table :content_types do |t|
      t.remove :protected_results
    end

    change_table :content_node_values do |t|
      t.remove :search_result
      t.remove :protected_result
    end
  end
end
