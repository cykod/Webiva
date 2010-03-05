require File.dirname(__FILE__) + "/../spec_helper"

describe ModulesController do

 integrate_views
 
  reset_domain_tables :site_modules

  before(:each) do
    mock_editor
  end

  it "should be able to display the list of modules" do

    get :index
    response.should render_template('modules/index')
  end

  it "should redisplay the page if we try to activate a module without its dependency" do
    post :index, :activate => true, :modules => {  :activate => ['blog'] }
    response.should render_template('modules/index')
  end

  it "should be able to activate available modules" do 

    # should change order of dependencies to run feedback first
    SiteModule.should_receive(:run_class_worker).with(:migrate_domain_components,:activation_list => [ 'feedback','blog'])

    post :index, :activate => true, :modules => {  :activate => ['blog','feedback'] }
    response.should redirect_to(:action => 'initializing' )

    SiteModule.count.should == 2
    mods = SiteModule.find(:all)
    mods[0].status.should =='initializing'
    mods[1].status.should =='initializing'

  end

  it "should be able to deactivate active modules" do
    mod_ids = SiteModule.activate_modules(['feedback','blog','feed'])

    # manually set to active - skip worker
    SiteModule.find(mod_ids).each { |mod|  mod.update_attribute(:status,'active' )}

    SiteModule.expire_site

    post :index, :deactivate => true, :modules => {  :deactivate => ['blog','feedback'] }

    SiteModule.find_by_name('blog').status.should == 'available'
    SiteModule.find_by_name('feedback').status.should == 'available'
    
    response.should redirect_to(:action => 'index')
   
  end

  it "shouldn't activate modules that dont exist" do

    post :index, :activate => true, :modules => {  :activate => ['testeramamama'] }
    response.should render_template('modules/index')
    SiteModule.count.should == 0
  end


end
