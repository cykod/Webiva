
class AdditionalCommentFields < ActiveRecord::Migration
  def self.up

    add_column :comments, :email, :string
    add_column :comments, :website, :string
  end

  def self.down
    remove_column :comments, :email
    remove_column :comments, :website
  end
end
