require File.dirname(__FILE__) + "/../spec_helper"

describe EndUserTagSegmentField do
  reset_domain_tables :end_users, :tags, :end_user_tags, :user_segments, :user_segment_caches

  it "should only have valid EndUser fields" do
    obj = EndUserTagSegmentField.user_segment_fields_handler_info[:domain_model_class].new
    EndUserTagSegmentField.user_segment_fields.each do |key, value|
      obj.has_attribute?(value[:field]).should be_true
      obj.respond_to?(value[:display_field]).should be_true
    end
  end

  describe "EndUserTagType" do
    reset_domain_tables :end_users, :tags

    before(:each) do
      @user1 = EndUser.push_target('test1@test.dev')
      @user1.tag('robots, poster, one, two')
      @user2 = EndUser.push_target('test2@test.dev')
      @user2.tag('fake, flagger, three')
      @user3 = EndUser.push_target('test3@test.dev')
      @user3.tag('bunnies, one, two, three')

      @type = EndUserTagSegmentField::EndUserTagType
    end

    it "should be able to find user by tag" do
      @type.select_options.length.should == 8
      @type.is(EndUserTag, :end_user_id, :tag_id, 'One').count.should == 2
    end
  end

  it "has handler_data" do
    @user1 = EndUser.push_target('test1@test.dev', :first_name => 'First')
    @user2 = EndUser.push_target('test2@test.dev', :last_name => 'Last')
    @user1.tag 'one,two,three'
    @user2.tag 'one'

    EndUserTagSegmentField.get_handler_data([@user1.id, @user2.id], [:tag]).size.should == 2
  end

  it "can output field data" do
    @user1 = EndUser.push_target('test1@test.dev', :first_name => 'First')
    @user2 = EndUser.push_target('test2@test.dev', :last_name => 'Last')
    @user1.tag 'one,two,three'
    @user2.tag 'one'

    handler_data = EndUserTagSegmentField.get_handler_data([@user1.id, @user2.id], [:num_tags, :tag])
    EndUserTagSegmentField.field_output(@user1, handler_data, :num_tags).should == 3

    EndUserTagSegmentField.user_segment_fields.each do |key, value|
      next if value[:search_only]
      EndUserTagSegmentField.field_output(@user1, handler_data, key)
    end
  end

  it "should be able to sort on sortable fields" do
    @user1 = EndUser.push_target('test1@test.dev', :first_name => 'First')
    @user2 = EndUser.push_target('test2@test.dev', :last_name => 'Last')
    @user1.tag 'one,two,three'
    @user2.tag 'one'

    ids = [@user1.id, @user2.id]
    seg = UserSegment.create :name => 'Test', :segment_type => 'custom'
    seg.id.should_not be_nil
    seg.add_ids ids

    EndUserTagSegmentField.user_segment_fields.each do |key, value|
      next unless value[:sortable]
      scope = EndUserTagSegmentField.sort_scope(key.to_s, 'DESC')
      scope.should_not be_nil

      seg.order_by = key.to_s
      seg.sort_ids(ids).should be_true
      seg.status.should == 'finished'
      seg.end_user_ids.size.should == 2
    end
  end
end
