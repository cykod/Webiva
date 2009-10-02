# Copyright (C) 2009 Pascal Rettig.

    
class InitialFeedTables < ActiveRecord::Migration
  def self.up
    create_table :cached_feeds do |t|
      t.column :href, :string
      t.column :title, :string
      t.column :link, :string
      t.column :feed_data, :text
      t.column :feed_data_type, :string
      t.column :http_headers, :text
      t.column :last_retrieved, :datetime
      t.column :time_to_live, :integer
      t.column :serialized, :text
      t.column :archived, :boolean, :default => false
    end
  end

  def self.down
    drop_table :cached_feeds
  end
end

