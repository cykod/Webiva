require File.dirname(__FILE__) + "/../spec_helper"


describe SiteWidget do

  reset_domain_tables :site_widgets

  it "should return the list of core widgets" do
 
    widgets = SiteWidget.core_widgets

    # Make sure we have some core widgets in there
    widgets.detect { |widget| widget[1] == "information" && widget[0] == "dashboard/core_widget" }.should_not be_nil
    widgets.detect { |widget| widget[1] == "updates" && widget[0] == "dashboard/content_node_widget" }.should_not be_nil
  end


end
