def selenium_text_clean(text)
  text.gsub("y",'') # no y's - http://jira.openqa.org/browse/SRC-385
end


Given /^a subpage of "([^\"]*)" called "([^\"]*)"$/ do |base_page, page_title|
  page = fetch_page_from_path(base_page)
  
  page.add_subpage(page_title)
end

When /^I edit the page "([^\"]*)"$/ do |page_path|
  @editor_page = fetch_page_from_path(page_path)
  visit "/website/edit/page/page/#{@editor_page.id}"
  selenium.wait_for :wait_for => :page
end

When /^I enter "([^\"]*)" into the first basic paragraph$/ do |text|
  
  selenium.select_frame('cms_paragraph_html_editor_1_ifr')
  
  selenium.focus('tinymce')
  text = selenium_text_clean(text)
  # Need to manually activate the tinymce instance
  selenium.type_keys('tinymce',text)
  selenium.select_frame('relative=parent')
end

Then /^I should see a paragraph containing "([^\"]*)"$/ do |text|
  text = selenium_text_clean(text)
  response.should contain(text)
end



When /^(?:|I )follow "([^\"]*)" and wait$/ do |button|
  click_link(button)
  selenium.wait_for :wait_for => :page
end


When /^(?:|I )press "([^\"]*)" and wait$/ do |button|
  click_button(button)
  selenium.wait_for :wait_for => :ajax
end
