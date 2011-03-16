require File.dirname(__FILE__) + "/../spec_helper"

describe EndUserSegmentType do

  reset_domain_tables :end_users

  describe "GenderType" do
    before(:each) do
      EndUser.push_target('test1@test.dev', :gender => 'm')
      EndUser.push_target('test2@test.dev', :gender => 'f')
      EndUser.push_target('test3@test.dev', :gender => 'f')

      @type = EndUserSegmentType::GenderType
    end

    it "should return users using based on gender" do
      @type.is(EndUser, :id, :gender, 'm').count.should == 1
      @type.is(EndUser, :id, :gender, 'f').count.should == 2
    end
  end

  describe "SourceType" do
    before(:each) do
      EndUser.push_target('test1@test.dev', :source => 'import')
      EndUser.push_target('test2@test.dev', :source => 'import')
      EndUser.push_target('test3@test.dev', :source => 'site')

      @type = EndUserSegmentType::SourceType
    end

    it "should return users using based on source" do
      @type.select_options.length.should == 3
      @type.is(EndUser, :id, :source, 'import').count.should == 2
      @type.is(EndUser, :id, :source, 'site').count.should == 1
    end
  end

  describe "LeadSourceType" do
    before(:each) do
      EndUser.push_target('test1@test.dev', :lead_source => 'import')
      EndUser.push_target('test2@test.dev', :lead_source => 'import')
      EndUser.push_target('test3@test.dev', :lead_source => 'site')

      @type = EndUserSegmentType::LeadSourceType
    end

    it "should return users using based on lead_source" do
      @type.select_options.length.should == 2
      @type.is(EndUser, :id, :lead_source, 'import').count.should == 2
      @type.is(EndUser, :id, :lead_source, 'site').count.should == 1
    end
  end
end
