require File.dirname(__FILE__) + "/../spec_helper"

describe EndUserSegmentField do
  reset_domain_tables :end_users

  it "should only have valid EndUser fields" do
    obj = EndUserSegmentField.user_segment_fields_handler_info[:domain_model_class].new
    EndUserSegmentField.user_segment_fields.each do |key, value|
      obj.has_attribute?(value[:field]).should be_true
      obj.respond_to?(value[:display_field]).should be_true
    end
  end

  it "has no handler_data" do
    @user1 = EndUser.push_target('test1@test.dev', :first_name => 'First')
    @user2 = EndUser.push_target('test2@test.dev', :last_name => 'Last')
    EndUserSegmentField.get_handler_data([@user1.id, @user2.id], [:first_name, :last_name]).should be_nil
  end

  it "can output field data" do
    @user1 = EndUser.push_target('test1@test.dev', :first_name => 'First')
    @user2 = EndUser.push_target('test2@test.dev', :last_name => 'Last')
    EndUserSegmentField.field_output(@user1, nil, :first_name).should == 'First'

    EndUserSegmentField.user_segment_fields.each do |key, value|
      next if value[:search_only]
      EndUserSegmentField.field_output(@user1, nil, key)
    end
  end

  it "should be able to sort on sortable fields" do
    @user1 = EndUser.push_target('test1@test.dev', :first_name => 'First')
    @user2 = EndUser.push_target('test2@test.dev', :last_name => 'Last')
    EndUserSegmentField.user_segment_fields.each do |key, value|
      next unless value[:sortable]
      EndUserSegmentField.sort_scope(key, 'DESC').find(:all).size.should == 2
    end
  end
end
