require File.dirname(__FILE__) + "/../spec_helper"

describe Domain do

  reset_system_tables :domains

  it "should require a name" do
    domain = Domain.new
    domain.valid?.should be_false
  end
end
