require File.dirname(__FILE__) + "/../spec_helper"

describe ExperimentVersion do

  # reset_domain_tables :experiment, :experiment_version, :experiment_user, :site_node, :site_version

  it "should require a name and a container" do
    exp = ExperimentVersion.new
    exp.should have(1).error_on(:language)
    exp.should have(1).error_on(:weight)
    exp.should have(1).error_on(:experiment_id)
  end

  it "should be able to create a version" do
    exp = ExperimentVersion.create :language => 'en', :revision => 0.01, :weight => 50, :experiment_id => 1
    exp.id.should_not be_nil
  end
end
