Feature: Manipulating the site tree on the structure page


   So that a user can build their site tree
   As an administrator
   I want to be able to add and edit site nodes and modifiers


@structure
  Background: Blank site structure
     Given a blank site
     When I log in as an editor
     When I visit the structure page

  Scenario: Adding pages to the site
     When I add a page called "test-page" to "/"
     When I add a page called "sub-test-page" to "/test-page"
     Then I should have a page called "/test-page/sub-test-page"
     
  Scenario: Building a site tree with modifiers
     When I add a page called "about-us" to "/"
     When I add a page called "who-we-are" to "/about-us"
     When I add a page called "what-we-do" to "/about-us"
     When I add a page called "catalog" to "/"
     When I add a page called "blog" to "/"
     When I add a page called "contact-us" to "/"
     When I add a "template" modifier to "Root"
     When I add a "lock" modifier to "/about-us"
     When I click on the lock edit information
     When I add "Profile: Default" to the ordered selection list "mod_access_authorized"
     When I submit the ajax form via "lock_commit_button" 
     Then I should have a "lock" modifier before "/about-us"
     And the lock modifier on "/about-us" should not allow "anonymous_class"
     And the lock modifier on "/about-us" should allow "default_user_class"
     And I should have a "template" modifier before "Root"
     
  Scenario: Editing a page's meta-info
     When I add a page called "about-us" to "/"
     When I add a page called "blog" to "/"
     When I select the page "/about-us"
     When I click on the page edit information
     When I fill in "Title" with "About Us Title"
     When I fill in "Menu title" with "About Menu Title" 
     When I fill in "Keywords" with "These be my keywords" 
     When I fill in "Description" with "This is the Description" 
     When I fill in "Notes" with "Some Notes go here" 
     When I submit the ajax form via "revision_edit_commit_button"
     Then the page "/about-us" should have a "title" of "About Us Title"
     And the page "/about-us" should have a "menu_title" of "About Menu Title"
     And the page "/about-us" should have a "meta_keywords" of "These be my keywords"
     And the page "/about-us" should have a "meta_description" of "This is the Description"
     And the page "/about-us" should have a "note" of "Some Notes go here"
     
   Scenario: Adding a external redirect     
     When I add a page called "subpage" to "/"
     When I add a redirect called "go" to "/subpage"
     When I click on the edit redirect information
     When I choose "An External URL"
     When I fill in "External Redirect URL" with "http://www.google.com"
     When I submit the ajax form via "redirect_commit_button"
     Then visiting "/subpage/go" should redirect to "http://www.google.com/"

   Scenario: Adding a internal redirect     
     When I add a page called "subpage" to "/"
     When I add a page called "destination" to "/"
     When I add a redirect called "go" to "/subpage"
     When I click on the edit redirect information
     When I choose "A Different Page"
     When I fill in "Redirect site node" with page "/destination"
     When I submit the ajax form via "redirect_commit_button"
     Then visiting "/subpage/go" should redirect to "/destination"

    
   Scenario: Adding a group 
     When I add a page called "group" to "/"
     When I add a group called "grouper" to "/group"
     When I add a page called "group-subpage-1" to group "/group/"
     When I add a page called "group-subpage-2" to group "/group/"
     Then I should have a page called "/group/group-subpage-1"
     And I should have a page called "/group/group-subpage-2"


   Scenario: Adding and viewing a document
     Given a file in the file manager called "rails.png"
     When I add a document called "my_rails_png.png" to "/"
     When I click the popup link called "Select a File"
     When I select the file manager file "/rails.png"
     Then visiting "/my_rails_png.png" should display the image "my_rails_png.png"


  Scenario: Load up the page editor 
     When I add a page called "test-page" to "/"
     When I follow "Edit Page"
     Then I should be taken to the page editor for "/test-page"

