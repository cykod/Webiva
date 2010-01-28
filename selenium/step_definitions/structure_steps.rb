
def fetch_page_from_path(page_path)
  if page_path == "Root"
    page =  SiteVersion.default.root
  else
    page = SiteNode.find_by_node_path_and_node_type(page_path,'P')
  end

end

def fetch_group_from_path(group_path)
   page = SiteNode.find_by_node_path_and_node_type(group_path,'G')
end

Given /^a blank site$/ do
  DatabaseCleaner.clean
  Domain.initial_domain_data
  visit '/website/manage/access/logout'
  selenium.wait_for :wait_for => :page
end

Given /^a running background process$/ do
  `RAILS_ENV=test #{RAILS_ROOT}/script/background.rb restart`
end


When /^I log in as an editor$/ do
  user = EndUser.new(:email => 'selenium@test.host', :password => '123456', :password_confirmation => '123456',:registered => true)
  user.user_class_id = 2
  user.client_user_id = 1
  user.save
  visit '/website'

  selenium.type  'user_username', 'selenium@test.host'
  selenium.type 'user_password', '123456'
  selenium.click "user_submit"
  selenium.wait_for :wait_for => :page
  
end


When /^I visit the structure page$/ do
  visit '/website/structure'
end


When /^I add a (page|redirect|document|group) called "([^\"]*)" to( group)? "([^\"]*)"$/ do |node_type,page_title,group,page_path|
  if group
    page = fetch_group_from_path(page_path)
    raise "Invalid existing group" unless page
  else
    page = fetch_page_from_path(page_path)
    raise "Invalid existing page" unless page
  end

  selenium.drag_and_drop_to_object('add_' + node_type,"node_line_#{page.id}")
  selenium.wait_for :wait_for => :ajax
  created_page = SiteNode.find(:last)

  selenium.type "css=#node_title_edit_#{created_page.id} input", page_title 
  selenium.key_press_native(10)
  selenium.wait_for :wait_for => :ajax # Wait twice, one to add modifier
  selenium.wait_for :wait_for => :ajax # second for element info

end

Then /^I should have a page called "([^\"]*)"$/ do |page_path|
  page = fetch_page_from_path(page_path)
  page.should_not be_nil
end


When /^I select the page "([^\"]*)"$/ do |page_path|
  page = fetch_page_from_path(page_path)
  click_link "node_title_#{page.id}"
  selenium.wait_for  :wait_for => :ajax
end


When /^I submit the ajax form via "([^\"]*)"$/ do |button_name|
  selenium.click button_name, :wait_for => :ajax
end

When /^I click on the page edit information$/ do
  selenium.click "css=.page_information_link"
end


Then /^the page "([^\"]*)" should have a "([^\"]*)" of "([^\"]*)"$/ do |page_path,field,value|
  page = fetch_page_from_path(page_path)
  rev = page.active_revisions[0]
  rev.send(field).should == value
 
end


When /^I add a "([^\"]*)" modifier to "([^\"]*)"$/ do |modifier_type, page_path|
  page = fetch_page_from_path(page_path)
  
  raise "Invalid existing page" unless page
  selenium.drag_and_drop_to_object('add_' + modifier_type,"node_line_#{page.id}")
  selenium.wait_for :wait_for => :ajax # Wait twice, one to add modifier
  selenium.wait_for :wait_for => :ajax # second for element info
end

When /^I click on the lock edit information$/ do
  selenium.click "css=.lock_information_link"
end

When /^I click on the edit redirect information$/ do
  selenium.click "css=.redirect_information_link"
end

When /^I add "([^\"]*)" to the ordered selection list "([^\"]*)"$/ do |option, identifier|
  select option, :from => "#{identifier}_select"
  selenium.click "#{identifier}_add"
end

Then /^I should have a "([^\"]*)" modifier (before|after) "([^\"]*)"$/ do |modifier_type,position, page_path|
  page = fetch_page_from_path(page_path)
  mod = page.site_node_modifiers.detect { |mod| mod.modifier_type == modifier_type }
  
  mod.should_not be_nil

  if position=='before'
    mod.position.should < page.page_modifier.position
  else
    mod.position.should > page.page_modifier.position

  end
  
end

Then /^the lock modifier on "([^\"]*)" should( not)? allow "([^\"]*)"$/ do |page_path,disallow,user_class|
  page = fetch_page_from_path(page_path)

  usr = EndUser.new
  usr.user_class_id = UserClass.send("#{user_class}_id")

  mod = page.site_node_modifiers.detect {  |mod| mod.modifier_type == "lock" }
  raise "invalid modifier" unless mod

  if disallow
    mod.access(usr).should == :locked
  else
    [:full,:unlocked].should include(mod.access(usr))
  end

end


Then /^visiting "([^\"]*)" should redirect to "([^\"]*)"$/ do |page_path,destination|
  visit page_path
  selenium.wait_for :wait_for => :page
  if(!(destination =~ /^http\:\/\//)) 
    destination = "http://#{SELENIUM_SITE_BASE}#{destination}"
  end

  current_url.should == destination
end


Given /^a file in the file manager called "([^\"]*)"$/ do |file_name|
  fdata = fixture_file_upload("files/#{file_name}",'image/png')
  @domain_file = DomainFile.create(:filename => fdata)
end

When /^I click the popup link called "([^\"]*)"$/ do |link_name|
  selenium.click "link=#{link_name}"
  selenium.wait_for_pop_up("null",3000)
  selenium.select_window(selenium.all_window_names[-1])
end

When /^I select the file manager file "([^\"]*)"$/ do |file_path|
  domain_file = DomainFile.find_by_file_path(file_path)

  selenium.double_click "item_#{domain_file.id}"
  selenium.select_window("null") # get the main window
end

Then /^visiting "([^\"]*)" should display the image "([^\"]*)"$/ do |page_path,image_path|
  visit page_path
  selenium.wait_for :wait_for => :page
  response.body.should include(image_path) # Fixme / TODO 
end

When /^(?:|I )fill in "([^\"]*)" with page "([^\"]*)"$/ do |field, value|
  node = SiteNode.find_by_node_path(value)
  raise "Invalid page selector page" unless node
  node_id = node.id
  When "I fill in \"#{field}\" with \"#{node_id}\""
end

Then /^I should be taken to the page editor for "([^\"]*)"$/ do |page_path|
  selenium.wait_for :wait_for => :page
  page = fetch_page_from_path(page_path)
  current_url.should =~ /\/website\/edit\/page\/page\/#{page.id}/
end
