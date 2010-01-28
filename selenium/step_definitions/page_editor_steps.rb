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

When /^I enter "([^\"]*)" into basic paragraph ([0-9]+)( and press return)?$/ do |text,para_id,press_return|
  para_id =para_id.to_i - 1
  editor_id= selenium.get_eval("window.cmsEdit.htmlEditorList()[#{para_id}].id")
  selenium.get_eval("window.tinyMCE.get('#{editor_id}').focus();")
  selenium.get_eval("window.cmsEdit.showToolbar('#{editor_id}}');")
  selenium.select_frame("#{editor_id}_ifr")
  selenium.focus('tinymce')
  
  text = selenium_text_clean(text)
  # Need to manually activate the tinymce instance
  selenium.type_keys('tinymce',text)
  if press_return
     selenium.key_press_native(10)
  end
  selenium.select_frame('relative=parent')
end


When /^I press enter in basic paragraph ([0-9]+)$/ do |para_id|
  para_id =para_id.to_i - 1
  editor_id= selenium.get_eval("window.cmsEdit.htmlEditorList()[#{para_id}].id")
  selenium.get_eval("window.tinyMCE.get('#{editor_id}').focus();")
  selenium.get_eval("window.cmsEdit.showToolbar('#{editor_id}}');")
  selenium.select_frame("#{editor_id}_ifr")
  selenium.focus('tinymce')
  
  # Need to manually activate the tinymce instance
  selenium.key_press_native(10)
  selenium.select_frame('relative=parent')
end


When /^I changed the format of basic paragraph ([0-9]+) to "([^\"]*)"$/ do |para_id,header|
  para_id =para_id.to_i - 1
  editor_id= selenium.get_eval("window.cmsEdit.htmlEditorList()[#{para_id}].id")

  selenium.click "#{editor_id}_formatselect_text"
  selenium.click "css=#menu_#{editor_id}_#{editor_id}_formatselect_menu_tbl .mceText[title=#{header}]"
end


Then /^I should see a paragraph containing "([^\"]*)"$/ do |text|
  text = selenium_text_clean(text)
  response.body.should include(text)
end



When /^(?:|I )follow "([^\"]*)" and wait$/ do |button|
  click_link(button)
  selenium.wait_for :wait_for => :page
end


When /^(?:|I )press "([^\"]*)" and wait$/ do |button|
  click_button(button)
  selenium.wait_for :wait_for => :ajax
end

When /^I click the file manager link of basic paragraph ([1-9]+)$/ do |para_id|
  para_id =para_id.to_i - 1
  editor_id= selenium.get_eval("window.cmsEdit.htmlEditorList()[#{para_id}].id")

  selenium.click "#{editor_id}_filemanager"
  selenium.wait_for_pop_up("null",3000)
  selenium.select_window(selenium.all_window_names[-1])
end


Then /^I should see a paragraph containing the file manager image "([^\"]*)"$/ do |file_path|
  domain_file = DomainFile.find_by_file_path(file_path)
  response.body.should include(domain_file.url)
end
