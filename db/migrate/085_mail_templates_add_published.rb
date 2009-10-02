
class MailTemplatesAddPublished < ActiveRecord::Migration
  def self.up
      
    add_column :mail_templates, :published_at, :datetime
  end

  def self.down
    remove_column :mail_templates, :published_at
  end
end
