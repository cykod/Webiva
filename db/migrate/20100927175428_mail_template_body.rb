class MailTemplateBody < ActiveRecord::Migration
  def self.up
    add_column :mail_templates, :body_html_display, :text
  end

  def self.down
    remove_column :mail_templates, :body_html_display
  end
end
