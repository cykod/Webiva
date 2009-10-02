class AddMailTemplateLastSent < ActiveRecord::Migration
  def self.up
    add_column :mail_templates, :last_sent_at, :datetime
  end

  def self.down
    remove_column :mail_templates, :last_sent_at
  end
end
