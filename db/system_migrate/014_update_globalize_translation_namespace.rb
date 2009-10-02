class UpdateGlobalizeTranslationNamespace < ActiveRecord::Migration
  def self.up
    add_column :globalize_translations, :namespace, :string
  end

  def self.down
    remove_column :globalize_translations, :namespace
  end
end
