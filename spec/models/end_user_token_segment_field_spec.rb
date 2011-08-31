require File.dirname(__FILE__) + "/../spec_helper"

describe EndUserTokenSegmentField do
  it "should only have valid EndUserToken fields" do
    obj = EndUserTokenSegmentField.user_segment_fields_handler_info[:domain_model_class].new
    EndUserTokenSegmentField.user_segment_fields.each do |key, value|
      if value[:field].is_a?(Array)
        value[:field].each { |fld| obj.has_attribute?(fld).should be_true }
      else
        obj.has_attribute?(value[:field]).should be_true
      end
      obj.respond_to?(value[:display_field]).should be_true
    end
  end
end
