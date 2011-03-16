require  File.expand_path(File.dirname(__FILE__)) + '/../simple_content_spec_helper'

describe ContentHashModelFeature do

  it "should support the following functions" do
    feature = ContentHashModelFeature.new nil
    feature.feature_handler = 'content/core_feature/email_target_connect'
    feature.feature.should_not be_nil
    feature.feature_instance.should_not be_nil
    feature.options_partial.should_not be_nil
    feature.options.should_not be_nil
    feature.name.should_not be_nil
    feature.description.should_not be_nil
    feature.respond_to?('update_callbacks').should be_true
    feature.respond_to?('model_generator').should be_true
    feature.respond_to?('webform').should be_true
    feature.respond_to?('feature_options').should be_true
    feature.respond_to?('model_generator_callback').should be_true
    feature.respond_to?('more_table_actions_callback').should be_true
    feature.respond_to?('table_columns_callback').should be_true
    feature.respond_to?('header_actions_callback').should be_true
    feature.respond_to?('add_migration_callback').should be_true
    feature.respond_to?('remove_migration_callback').should be_true
  end
end
