require File.dirname(__FILE__) + "/../spec_helper"

describe EndUserActionSegmentField do

  reset_domain_tables :end_users, :end_user_actions, :user_segments, :user_segment_caches

  it "should only have valid EndUserAction fields" do
    obj = EndUserActionSegmentField.user_segment_fields_handler_info[:domain_model_class].new
    EndUserActionSegmentField.user_segment_fields.each do |key, value|
      if value[:field].is_a?(Array)
        value[:field].each { |fld| obj.has_attribute?(fld).should be_true }
      else
        obj.has_attribute?(value[:field]).should be_true
      end
      obj.respond_to?(value[:display_field]).should be_true
    end
  end

  it "has handler_data" do
    @user1 = EndUser.push_target('test1@test.dev', :first_name => 'First')
    @user2 = EndUser.push_target('test2@test.dev', :last_name => 'Last')

    EndUserAction.create :end_user_id => @user1.id, :level => 3, :renderer => 'editor/auth', :action => 'login'
    EndUserAction.create :end_user_id => @user2.id, :level => 3, :renderer => 'editor/auth', :action => 'login'

    EndUserActionSegmentField.get_handler_data([@user1.id, @user2.id], [:renderer, :action]).size.should == 2
  end

  it "can output field data" do
    @user1 = EndUser.push_target('test1@test.dev', :first_name => 'First')
    @user2 = EndUser.push_target('test2@test.dev', :last_name => 'Last')
    EndUserAction.create :end_user_id => @user1.id, :level => 3, :renderer => 'editor/auth', :action => 'login'
    EndUserAction.create :end_user_id => @user1.id, :level => 3, :renderer => 'editor/auth', :action => 'login'
    EndUserAction.create :end_user_id => @user2.id, :level => 3, :renderer => 'editor/auth', :action => 'login'

    handler_data = EndUserActionSegmentField.get_handler_data([@user1.id, @user2.id], [:renderer, :action])
    EndUserActionSegmentField.field_output(@user1, handler_data, :num_actions).should == 2

    EndUserActionSegmentField.user_segment_fields.each do |key, value|
      next if value[:search_only]
      EndUserActionSegmentField.field_output(@user1, handler_data, key)
    end
  end

  it "should be able to sort on sortable fields" do
    @user1 = EndUser.push_target('test1@test.dev', :first_name => 'First')
    @user2 = EndUser.push_target('test2@test.dev', :last_name => 'Last')

    EndUserAction.create :end_user_id => @user1.id, :level => 3, :renderer => 'editor/auth', :action => 'login'
    EndUserAction.create :end_user_id => @user1.id, :level => 3, :renderer => 'editor/auth', :action => 'login'
    EndUserAction.create :end_user_id => @user2.id, :level => 3, :renderer => 'editor/auth', :action => 'login'

    ids = [@user1.id, @user2.id]
    seg = UserSegment.create :name => 'Test', :segment_type => 'custom'
    seg.id.should_not be_nil
    seg.add_ids ids

    EndUserActionSegmentField.user_segment_fields.each do |key, value|
      next unless value[:sortable]
      scope = EndUserActionSegmentField.sort_scope(key.to_s, 'DESC')
      scope.should_not be_nil

      seg.order_by = key.to_s
      seg.sort_ids(ids).should be_true
      seg.status.should == 'finished'
      seg.end_user_ids.size.should == 2
    end
  end
end
