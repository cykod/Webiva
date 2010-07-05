require File.dirname(__FILE__) + "/../spec_helper"

describe EndUserCacheSegmentField do
  it "should only have valid EndUser fields" do
    obj = EndUserCacheSegmentField.user_segment_fields_handler_info[:domain_model_class].new
    EndUserCacheSegmentField.user_segment_fields.each do |key, value|
      obj.has_attribute?(value[:field]).should be_true
      obj.respond_to?(value[:display_field]).should be_true
    end
  end
end
