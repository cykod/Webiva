require File.dirname(__FILE__) + "/../spec_helper"


describe EditorWidget do

  reset_domain_tables :site_widgets, :editor_widgets, :roles, :end_users, :user_roles

  it "should be able to assemble a list of site widgets" do

    user = mock_editor
    
    widget = SiteWidget.create(:widget_identifier => "dashboard/core_widget:information",
                               :title => 'Test Widget 1',
                               :column => 0, :weight => 0,
                               :data => {  :body => 'Test Body'})
    widget2 = SiteWidget.create(:widget_identifier => "dashboard/content_node_widget:updates",
                                :title => 'Test Widget 2',
                               :column => 0, :weight => -1)
    widget3 = SiteWidget.create(:widget_identifier => "dashboard/content_node_widget:updates",
                                :title => 'Test Widget 3',
                               :column => 1, :weight => 2)
    # Should return a bunch of EditorWidgets in the right order
    widgets = EditorWidget.assemble_widgets(user)

    
    widgets.length.should == 3
    widgets[0].length.should == 2
    widgets[1].length.should == 1

    widgets[0][0].widget_class.to_s.should == 'Dashboard::ContentNodeWidget'
    widgets[0][1].widget_class.to_s.should == "Dashboard::CoreWidget"
    widgets[1][0].widget_class.to_s.should == 'Dashboard::ContentNodeWidget'
  end


end
