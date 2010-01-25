


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
     When I enter "This is a test of the emergency broadcast system" into the first basic paragraph
     When I press "Save Changes" and wait
     When I follow "Goto Page" and wait 
     Then I should see a paragraph containing "This is a test of the emergency broadcast system"
