require File.dirname(__FILE__) + "/../spec_helper"

describe ExperimentUser do

  reset_domain_tables :experiment, :experiment_version, :experiment_user, :site_node, :site_version

  it "should require a name and a container" do
    exp = ExperimentUser.new
    exp.should have(1).error_on(:domain_log_visitor_id)
    exp.should have(1).error_on(:language)
    exp.should have(1).error_on(:experiment_id)
    exp.should have(1).error_on(:experiment_version_id)
  end

  it "should be able to create a experiment user" do
    exp = ExperimentUser.create :domain_log_visitor_id => 1, :language => 'en', :experiment_id => 1, :experiment_version_id => 2
    exp.id.should_not be_nil
    exp.success.should be_false
    exp.success!
    exp.reload
    exp.success.should be_true
  end
end
