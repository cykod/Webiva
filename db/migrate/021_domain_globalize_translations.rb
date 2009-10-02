class DomainGlobalizeTranslations < ActiveRecord::Migration

  def self.up
   create_table :globalize_translations, :force => true do |t|
      t.column :type,           :string
      t.column :tr_key,         :string
      t.column :table_name,     :string
      t.column :item_id,        :integer
      t.column :facet,          :string
      t.column :language_id,    :integer
      t.column :pluralization_index, :integer
      t.column :text,           :text
    end

    add_index :globalize_translations, [ :tr_key, :language_id ]
    add_index :globalize_translations, [ :table_name, :item_id, :language_id ], :name => 'table_item_language'

  end

  def self.down
  end
end
