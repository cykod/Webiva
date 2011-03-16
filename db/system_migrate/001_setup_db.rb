class SetupDb < ActiveRecord::Migration
  def self.up

   execute "ALTER DATABASE #{ActiveRecord::Base.connection.current_database} CHARACTER SET utf8 COLLATE utf8_unicode_ci"


    create_table "client_permissions", :id => false, :force => true do |t|
      t.column "perm_id", :integer, :default => 0, :null => false
      t.column "perm_source", :string, :limit => 4, :default => "", :null => false
      t.column "perm_source_id", :integer, :default => 0, :null => false
      t.column "perm_dest", :string, :limit => 4, :default => "", :null => false
      t.column "perm_dest_id", :integer, :default => 0, :null => false
      t.column "perm_access", :string, :limit => 6, :default => "", :null => false
    end
  
    create_table "client_roles", :id => false, :force => true do |t|
      t.column "role_id", :integer, :default => 0, :null => false
      t.column "role_source", :string, :limit => 4, :default => "", :null => false
      t.column "role_source_id", :integer, :default => 0, :null => false
      t.column "role_name", :string, :limit => 16, :default => "", :null => false
    end
  
    add_index "client_roles", ["role_name", "role_source", "role_source_id"], :name => "role_name"
    add_index "client_roles", ["role_source", "role_source_id"], :name => "role_source"
  
    create_table "client_users", :force => true do |t|
      t.column "client_id", :integer, :default => 0, :null => false
      t.column "username", :string, :default => "", :null => false
      t.column "hashed_password", :string, :limit => 64, :default => "", :null => false
      t.column "client_admin", :boolean
      t.column "system_admin", :boolean
      t.column "email", :string, :default => ""
    end
  
    create_table "clients", :force => true do |t|
      t.column "name", :string, :limit => 100, :default => "", :null => false
      t.column "domain_limit", :integer, :default => 1, :null => false
    end
  
    create_table "domain_modules", :force => true do |t|
      t.column "name", :string
      t.column "domain_id", :integer
      t.column "status", :string, :default => ""
      t.column "options", :binary
    end
  
    create_table "domains", :force => true do |t|
      t.column "name", :string, :default => "", :null => false
      t.column "database", :string, :default => "", :null => false
      t.column "client_id", :integer, :default => 0, :null => false
      t.column "status", :string, :default => 'initializing'
    end
  
    create_table "globalize_countries", :force => true do |t|
      t.column "code", :string, :limit => 2
      t.column "english_name", :string
      t.column "date_format", :string
      t.column "currency_format", :string
      t.column "currency_code", :string, :limit => 3
      t.column "thousands_sep", :string, :limit => 2
      t.column "decimal_sep", :string, :limit => 2
      t.column "currency_decimal_sep", :string, :limit => 2
      t.column "number_grouping_scheme", :string
    end
  
    add_index "globalize_countries", ["code"], :name => "globalize_countries_code_index"
  
    create_table "globalize_languages", :force => true do |t|
      t.column "iso_639_1", :string, :limit => 2
      t.column "iso_639_2", :string, :limit => 3
      t.column "iso_639_3", :string, :limit => 3
      t.column "rfc_3066", :string
      t.column "english_name", :string
      t.column "english_name_locale", :string
      t.column "english_name_modifier", :string
      t.column "native_name", :string
      t.column "native_name_locale", :string
      t.column "native_name_modifier", :string
      t.column "macro_language", :boolean
      t.column "direction", :string
      t.column "pluralization", :string
      t.column "scope", :string, :limit => 1
    end
  
    add_index "globalize_languages", ["iso_639_1"], :name => "globalize_languages_iso_639_1_index"
    add_index "globalize_languages", ["iso_639_2"], :name => "globalize_languages_iso_639_2_index"
    add_index "globalize_languages", ["iso_639_3"], :name => "globalize_languages_iso_639_3_index"
    add_index "globalize_languages", ["rfc_3066"], :name => "globalize_languages_rfc_3066_index"
  
    create_table "globalize_translations", :force => true do |t|
      t.column "type", :string
      t.column "tr_key", :string
      t.column "table_name", :string
      t.column "item_id", :integer
      t.column "facet", :string
      t.column "language_id", :integer
      t.column "pluralization_index", :integer
      t.column "text", :text
      t.column "built_in", :boolean, :default => false
    end
  
    add_index "globalize_translations", ["tr_key", "language_id"], :name => "globalize_translations_tr_key_index"
    add_index "globalize_translations", ["table_name", "item_id", "language_id"], :name => "globalize_translations_table_name_index"
  end
      
  def self.down
    raise IrreversibleMigration
  end

end
