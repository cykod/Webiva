
class InitialRatingsTable < ActiveRecord::Migration
  def self.up

    create_table :feedback_ratings do |t|
      t.column :target_type, :string, :limit => 40
      t.column :target_id, :integer
      t.column :rating_sum, :integer, :default => 0
      t.column :rating_count, :integer, :default => 0
    end

    add_index :feedback_ratings, [:target_type, :target_id], :name => 'feedback_ratings_target_index'

    create_table :feedback_end_user_ratings do |t|
      t.column :target_type, :string, :limit => 40
      t.column :target_id, :integer
      t.column :end_user_id, :integer
      t.column :rating, :integer, :default => 0
      t.column :rated_at, :datetime
      t.column :rated_ip, :string
    end

    add_index :feedback_end_user_ratings, [:target_type, :target_id], :name => 'feedback_end_user_ratings_target_index'
    add_index :feedback_end_user_ratings, [:end_user_id], :name => 'feedback_end_user_ratings_end_user_index'
  end

  def self.down
    drop_table :feedback_ratings
    drop_table :feedback_end_user_ratings
  end
end
