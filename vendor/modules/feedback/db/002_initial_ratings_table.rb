
class InitialRatingsTable < ActiveRecord::Migration
  def self.up

    create_table :feedback_ratings do |t|
      t.column :target_type, :string, :limit => 20
      t.column :target_id, :integer
      t.column :rating, :decimal, :precision => 14, :scale => 2
      t.timestamps
    end

    add_index :feedback_ratings, [:target_type, :target_id], :name => 'feedback_ratings_target_index'

    create_table :feedback_end_user_ratings do |t|
      t.column :rating_id, :integer
      t.column :end_user_id, :integer
      t.column :rating, :integer
      t.column :rated_at, :datetime
      t.column :rated_ip, :integer
    end

    add_index :feedback_end_user_ratings, [:rating_id], :name => 'feedback_end_user_ratings_index'
    add_index :feedback_end_user_ratings, [:end_user_id], :name => 'feedback_end_user_ratings_end_user_index'
  end

  def self.down
    drop_table :feedback_ratings
    drop_table :feedback_end_user_ratings
  end
end
