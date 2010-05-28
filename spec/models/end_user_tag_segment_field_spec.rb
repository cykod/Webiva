require File.dirname(__FILE__) + "/../spec_helper"

describe EndUserTagSegmentField do
  it "should only have valid EndUser fields" do
    obj = EndUserTagSegmentField.user_segment_fields_handler_info[:domain_model_class].new
    EndUserTagSegmentField.user_segment_fields.each do |key, value|
      obj.has_attribute?(value[:field]).should be_true
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
      @type.is(EndUserTag, :tag_id, 'One').count.should == 2
    end
  end
end
