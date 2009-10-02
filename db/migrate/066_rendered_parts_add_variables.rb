class RenderedPartsAddVariables < ActiveRecord::Migration
  def self.up
    add_column :site_template_rendered_parts, :variable, :string
    add_column :page_revisions, :variables, :text
  end

  def self.down
    remove_column :site_template_rendered_parts, :variable
    remove_column :page_revisions, :variables
  end
end
