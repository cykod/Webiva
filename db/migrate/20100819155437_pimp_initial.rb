class PimpInitial < ActiveRecord::Migration
  def self.up

    add_column :page_revisions, :identifier_hash, :string

    create_table :domain_log_visitors do |t|
      t.string :visitor_hash, :limit => 64
      t.string :ip_address
      t.decimal :latitude, :limit => 11, :precision => 11, :scale => 6
      t.decimal :longitude, :limit => 11, :precision => 11, :scale => 6
      t.string :country, :limit => 2
      t.string :region, :limt => 32
      t.string :city, :limit => 32
      t.integer :end_user_id
      t.timestamps
    end

    add_index :domain_log_visitors, :visitor_hash, :name => 'HashIndex'
    add_index :domain_log_visitors, :updated_at, :name => 'UpdatedIndex'
    add_index :domain_log_visitors, :end_user_id, :name => 'UserId'

    add_column :domain_log_sessions, :domain_log_visitor_id, :integer

    add_index :domain_log_sessions, :domain_log_visitor_id, :name => 'visitor_index'

    add_column :domain_log_entries, :content_node_id, :integer


    add_index :domain_log_entries, [ :site_node_id, :user_id ], :name => 'site_node_index'
    add_index :domain_log_entries, [ :content_node_id, :user_id ], :name => 'content_node_index'
    

    add_column :end_users, :acknowledged, :boolean, :default => 1

    create_table :domain_log_referrers do |t|
      t.string :referrer_domain, :limit => 64
      t.string :referrer_path, :limit => 128
      t.timestamps 
    end

    add_index :domain_log_referrers, [ :referrer_domain, :referrer_path, :created_at ], :name => 'Referrer'
    add_index :domain_log_referrers, :created_at, :name => 'CreatedIndex'

    begin
      remove_column :domain_log_sessions, :referrer_domain
      remove_column :domain_log_sessions, :referrer_path
    rescue Exception 
      # Chomp
    end
    add_column :domain_log_sessions, :domain_log_referrer_id, :integer
    add_column :domain_log_sessions, :query,:string, :limit => 64

    add_index :domain_log_sessions, :domain_log_referrer_id, :name => 'referrer_id'
   end

  def self.down
    remove_index :domain_log_sessions, :name => 'referrer_id'

    remove_column :domain_log_sessions, :domain_log_referrer_id

    remove_column :domain_log_sessions, :query

    drop_table :domain_log_referrers
    
    remove_column :end_users, :acknowledged

    remove_index  :domain_log_entries, :name => "content_node_index"
    remove_index :domain_log_entries, :name => "site_node_index"

    remove_column :domain_log_entries, :content_node_id

    remove_index  :domain_log_sessions, :name => 'visitor_index'

    remove_column :domain_log_sessions, :domain_log_visitor_id

    drop_table :domain_log_visitors

    remove_column :page_revisions, :identifier_hash
  end
end
