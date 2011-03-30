class ContentModelFieldNameChange < ActiveRecord::Migration
  def self.up
    self.connection.execute 'ALTER TABLE content_model_fields CHANGE field field_key varchar(255)'
  end

  def self.down
    self.connection.execute 'ALTER TABLE content_model_fields CHANGE field_key field varchar(255)'
  end
end
