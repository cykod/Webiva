


Feature: Editing pages in the page editor


   So that users can edit pages
   As an administrator
   I want to be able to edit pages

 
@editor
  Background: Blank site structure
     Given a blank site
     Given a subpage of "/" called "test-page"
     When I log in as an editor
     When I edit the page "/test-page"

  Scenario: Edit an save some text
     When I enter "This is a test of the emergency broadcast system" into basic paragraph 1
     When I press "Save Changes" and wait
     When I follow "Goto Page" and wait 
     Then I should see a paragraph containing "This is a test of the emergency broadcast system"

  Scenario: Style some text
     When I enter "This is going to be my header" into basic paragraph 1
     When I changed the format of basic paragraph 1 to "Heading 1"
     When I press enter in basic paragraph 1
     When I enter "This is going to be the rest of the paragraph" into basic paragraph 1
     When I press "Save Changes" and wait
     When I follow "Goto Page" and wait 
     Then I should see a paragraph containing "<h1>This is going to be my header</h1>"
     And I should see a paragraph containing "<p>This is going to be the rest of the paragraph</p>"

 Scenario: Inserting an image
     Given a file in the file manager called "rails.png"
     When I enter "This goes before the file" into basic paragraph 1
     When I click the file manager link of basic paragraph 1
     When I select the file manager file "/rails.png"
     When I enter "This goes after the file" into basic paragraph 1
     When I press "Save Changes" and wait
     When I follow "Goto Page" and wait 
     And I should see a paragraph containing the file manager image "/rails.png"