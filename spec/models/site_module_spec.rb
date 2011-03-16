require File.dirname(__FILE__) + "/../spec_helper"


describe SiteModule do

  reset_domain_tables :site_modules

  it "shouldn't allow activation of the blog modules without it's dependency" do
    
    SiteModule.generate_activation_list(['blog']).should be_false
  end

  it "should activate modules in the correct order" do 
    activation_list =  SiteModule.generate_activation_list(['blog','feedback','feed'])
    activation_list.should == ['feedback','blog','feed']
  end

  it "shouldnt activate modules that aren't available" do
    activation_list =  SiteModule.generate_activation_list(['blog','feedback','feed','testerama'])
    activation_list.should be_false
  end

  it "should be able to activate a list of modules" do
    activation_list =  SiteModule.generate_activation_list(['blog','feedback','feed'])
    activation_list.should == ['feedback','blog','feed']
    mod_ids = SiteModule.activate_modules(activation_list)

    mods = SiteModule.find(mod_ids)
    mods[0].name.should == 'feedback'
    mods[0].status.should == 'initializing'

    mods[1].name.should == 'blog'
    mods[1].status.should == 'initializing'

    mods[2].name.should == 'feed'
    mods[2].status.should == 'initializing'
    
  end

  it "should be able to post initialize each initialized module to make it active" do
    mod_ids = SiteModule.activate_modules(['feedback','blog','feed'])

    # manually set to initialized - skip worker
    mods = SiteModule.find(mod_ids).each { |mod|  mod.update_attribute(:status,'initialized' )}

    mods.each do |mod|
      mod.post_initialization!
    end

    mods = SiteModule.find(mod_ids)
    mods.each do |mod|
      mod.status.should == 'active'
    end
  end

  it "shouldn't allow deactivation of a dependency of an active module" do
    mod_ids = SiteModule.activate_modules(['feedback','blog','feed'])

    # manually set to active - skip worker
    SiteModule.find(mod_ids).each { |mod|  mod.update_attribute(:status,'active' )}

    SiteModule.expire_site
    # blog depends on feedback
    deactivation_list = SiteModule.generate_deactivation_list(['feedback','feed'])
    deactivation_list.should be_false
  end

   it "should allow deactivation of a dependency of an active module if that module is also deactivated" do
    mod_ids = SiteModule.activate_modules(['feedback','blog','feed'])

    # manually set to active - skip worker
    SiteModule.find(mod_ids).each { |mod|  mod.update_attribute(:status,'active' )}

    SiteModule.expire_site
    # blog depends on feedback
    deactivation_list = SiteModule.generate_deactivation_list(['feedback','feed','blog'])
    deactivation_list.should == ['feedback','feed','blog']
  end
 
  
end
