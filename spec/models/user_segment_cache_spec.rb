require File.dirname(__FILE__) + "/../spec_helper"

describe UserSegmentCache do

  reset_domain_tables :user_segments, :user_segment_caches, :end_users

  it "should require a user segment" do
    @cache = UserSegmentCache.new
    @cache.valid?.should be_false
    @cache.should have(1).error_on(:user_segment_id)
  end

end
