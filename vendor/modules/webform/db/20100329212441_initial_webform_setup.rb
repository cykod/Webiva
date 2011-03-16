class InitialWebformSetup < ActiveRecord::Migration
  def self.up
    create_table :webform_forms, :force => true do |t|
      t.string :name
      t.text :fields, :limit => 16777215
      t.text :features, :limit => 16777215
      t.timestamps
    end

    create_table :webform_form_results, :force => true do |t|
      t.integer :webform_form_id
      t.integer :end_user_id
      t.string :name
      t.text :data
      t.string :ip_address
      t.integer :domain_log_session_id
      t.boolean :reviewed
      t.datetime :posted_at
    end

    add_index :webform_form_results, :webform_form_id, :name => 'webform_form_result_form_idx'
    add_index :webform_form_results, :end_user_id, :name => 'webform_form_result_end_user_idx'
  end

  def self.down
    drop_table :webform_forms
    drop_table :webform_form_results
  end
end
