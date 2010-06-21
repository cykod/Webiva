require File.dirname(__FILE__) + "/../../spec_helper"

describe Manage::ClientsController do

  reset_system_tables :client_users, :clients, :domains, :domain_databases
  reset_domain_tables :end_users

  before(:each) do
    @domain = Domain.find CMS_DEFAULTS['testing_domain']
    @client = @domain.client
  end

  it "should only permit system administrators" do
    @user = @client.client_users.create :username => 'my_system_admin', :client_admin => 1, :system_admin => 1
    @myself = @user.end_user
    controller.should_receive('myself').at_least(:once).and_return(@myself)
    get 'index'
    response.should render_template('list')
  end

  it "should redirect if not a system admin" do
    @user = @client.client_users.create :username => 'my_system_admin', :client_admin => 1, :system_admin => 0
    @myself = @user.end_user
    controller.should_receive('myself').at_least(:once).and_return(@myself)
    get 'index'
    response.should redirect_to(:controller => '/manage/access', :action => 'denied')
  end
end
