class AddContentModelPreset < ActiveRecord::Migration
  def self.up
    add_column :content_models, :model_preset, :string
    add_column :content_models, :customized, :boolean
  end

  def self.down
    remove_column :content_models, :model_preset
    remove_column :content_models, :customized
  end
end
