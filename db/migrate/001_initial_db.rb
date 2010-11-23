class InitialDb < ActiveRecord::Migration
  def self.up

   execute "ALTER DATABASE #{ActiveRecord::Base.connection.current_database} CHARACTER SET utf8 COLLATE utf8_unicode_ci"

    create_table "access_groups", :force => true do |t|
      t.column "name", :string
      t.column "access_hierarchy_id", :string
      t.column "parent_id", :integer
    end
  
    create_table "access_hierarchies", :force => true do |t|
      t.column "name", :string
      t.column "hierarchy_type", :string
    end
  
    create_table "blog_entries", :force => true do |t|
      t.column "site_module_id", :integer
      t.column "title", :string
      t.column "body", :text
      t.column "post_on", :datetime
      t.column "invisible", :boolean
    end
  
    create_table "configurations", :force => true do |t|
      t.column "config_key", :string
      t.column "options", :text
    end
  
    add_index "configurations", ["config_key"], :name => "configurations_config_key_index"
  
    create_table "domain_files", :force => true do |t|
      t.column "parent_id", :integer
      t.column "filename", :string
      t.column "file_type", :string
      t.column "name", :string
      t.column "meta_info", :text
      t.column "file_path", :string
    end
  
    create_table "domain_files_mail_templates", :id => false, :force => true do |t|
      t.column "mail_template_id", :integer
      t.column "domain_file_id", :integer
    end
  
    create_table "domain_log_entries", :force => true do |t|
      t.column "user_model", :string
      t.column "user_id", :integer
      t.column "user_class", :string
      t.column "site_node_id", :integer
      t.column "node_path", :string
      t.column "page_path", :string
      t.column "paction", :string
      t.column "occurred_at", :string
      t.column "ip_address", :string
      t.column "session_id", :string
      t.column "status", :string
    end
  
    create_table "domain_users", :force => true do |t|
      t.column "username", :string
      t.column "email", :string
      t.column "hashed_password", :string
      t.column "name", :string
      t.column "language", :string, :limit => 10
    end
  
    create_table "end_users", :force => true do |t|
      t.column "email", :string
      t.column "hashed_password", :string
      t.column "language", :string, :limit => 10
      t.column "user_class_id", :integer
      t.column "verification_string", :string
      t.column "gender", :string
      t.column "first_name", :string
      t.column "last_name", :string
    end
  
    create_table "mail_templates", :force => true do |t|
      t.column "name", :string
      t.column "language", :string, :limit => 10
      t.column "subject", :string
      t.column "body_text", :text
      t.column "body_html", :text
      t.column "body_type", :string, :default => "text,html"
      t.column "attachments", :integer, :default => 0
    end
  
    create_table "page_paragraphs", :force => true do |t|
      t.column "page_revision_id", :integer, :default => 0, :null => false
      t.column "zone_idx", :integer, :default => 0, :null => false
      t.column "position", :integer, :default => 0, :null => false
      t.column "display_type", :string, :default => "text"
      t.column "display_body", :text
      t.column "name", :string
      t.column "display_module", :string
      t.column "site_module_id", :integer
      t.column "data", :text
      t.column "site_feature_id", :integer
    end
  
    create_table "page_revisions", :force => true do |t|
      t.column "title", :string, :default => "", :null => false
      t.column "revision", :decimal, :limit => 8, :precision => 8, :scale => 2, :default => 0.0
      t.column "active", :boolean, :default => false, :null => false
      t.column "language", :string, :limit => 10
      t.column "revision_container_type", :string, :limit => 100
      t.column "revision_container_id", :integer
      t.column "created_at", :datetime
      t.column "created_by_id", :integer
      t.column "edit_number", :integer, :default => 0
      t.column "menu_title", :string, :default => ""
      t.column "meta_keywords", :text
      t.column "meta_description", :text
      t.column "note", :text
      t.column "updated_at", :datetime
      t.column "updated_by", :integer
      t.column "revision_type", :string, :default => "real", :limit => 50
      t.column "created_by_type", :string
      t.column "updated_by_type", :string
      t.column "parent_revision_id", :integer
    end
  
    create_table "redirect_details", :force => true do |t|
      t.column "redirect_type", :string, :default => "site_node"
      t.column "redirect_site_node_id", :integer
      t.column "redirect_url", :string
      t.column "site_node_id", :integer
    end
  
    create_table "roles", :force => true do |t|
      t.column "name", :string, :limit => 40
      t.column "authorizable_type", :string, :limit => 30
      t.column "authorizable_id", :integer
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
    end
  
    create_table "site_features", :force => true do |t|
      t.column "site_template_id", :integer
      t.column "name", :string
      t.column "description", :string
      t.column "feature_type", :string
      t.column "body", :text
    end
  
    create_table "site_modules", :force => true do |t|
      t.column "name", :string
      t.column "description", :text
      t.column "module_name", :string
      t.column "options_data", :binary
    end
  
    create_table "site_node_modifiers", :force => true do |t|
      t.column "position", :integer
      t.column "modifier_type", :string
      t.column "site_node_id", :integer
      t.column "description", :text
      t.column "modifier_data", :text
    end
  
    add_index "site_node_modifiers", ["site_node_id"], :name => "site_node_modifiers_site_node_id_index"
  
    create_table "site_nodes", :force => true do |t|
      t.column "title", :string, :default => "", :null => false
      t.column "node_type", :string, :default => "P", :null => false
      t.column "parent_id", :integer
      t.column "children_count", :integer, :default => 0, :null => false
      t.column "position", :integer
      t.column "node_data", :integer
      t.column "node_path", :string
      t.column "node_level", :integer, :default => 0
      t.column "module_name", :string
    end
  
    create_table "site_template_rendered_parts", :force => true do |t|
      t.column "site_template_id", :integer
      t.column "zone_position", :integer
      t.column "part", :string
      t.column "body", :text
      t.column "language", :string
      t.column "idx", :integer
    end
  
    create_table "site_template_styles", :force => true do |t|
      t.column "element", :text
      t.column "styles", :text
      t.column "comment", :text
      t.column "parent", :integer
    end
  
    create_table "site_template_zones", :force => true do |t|
      t.column "site_template_id", :integer
      t.column "name", :string
      t.column "position", :integer
    end
  
    add_index "site_template_zones", ["site_template_id"], :name => "site_template_zones_site_template_id_index"
  
    create_table "site_templates", :force => true do |t|
      t.column "name", :string
      t.column "description", :text
      t.column "template_html", :text
      t.column "options", :text
      t.column "style_struct", :text
      t.column "style_design", :text
      t.column "modified_at", :datetime
      t.column "modified_by", :integer
      t.column "domain_file_id", :integer
    end
  
    create_table "user_classes", :force => true do |t|
      t.column "name", :string
      t.column "built_in", :boolean, :default => false
    end
  
    create_table "user_roles", :force => true do |t|
      t.column "authorized_type", :string
      t.column "authorized_id", :integer
      t.column "role_id", :integer
      t.column "created_at", :datetime
      t.column "updated_at", :datetime
    end
  
  end
  
  def self.down
    raise IrreversibleMigration  
  end
end
