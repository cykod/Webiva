Webiva::Application.routes.draw do
  scope '/website' do
    root :to => 'manage/access#login'

    namespace :editor do
      webiva_controllers_for('editor').each do |cntl|
        match "/#{cntl}(/:action(/*path))", :controller => cntl
      end
    end

    namespace :manage do
      webiva_controllers_for('manage').each do |cntl|
        match "/#{cntl}(/:action(/*path))", :controller => cntl
      end
    end

    webiva_base_controllers.each do |cntl|
      match "/#{cntl}(/:action(/*path))", :controller => cntl
    end
  end

  webiva_modules.each do |mod_name|
    scope '/website' do
      webiva_module_for mod_name
    end

    # allow modules to add their own specific routes
    webiva_module_routes mod_name
  end

  match '/view/:language/*path' => 'page#view', :as => :language_link
  
  match '/mailing/view/:campaign_hash/:queue_hash' => 'campaigns#view'
  match '/mailing/image/:campaign_hash/:queue_hash' => 'campaigns#image'
  match '/mailing/link/:campaign_hash/:link_hash/:queue_hash' => 'campaigns#link'

  match '/system/storage/:domain_id/*path' => 'public#image'
  match '/__fs__/*prefix' => 'public#file_store'
  match '/simple_captcha/:action' => 'simple_captcha#index', :as => :simple_captcha

  # match '/website/:controller(/:action(/*path))'
  match '/webalytics' => 'page#webalytics'
  match '/mailing/view/:campaign_hash/:queue_hash' => 'campaigns#view'
  match '/mailing/image/:campaign_hash/:queue_hash' => 'campaigns#image'
  match '/mailing/link/:campaign_hash/:link_hash/:queue_hash' => 'campaigns#link'
  match '/system/storage/:domain_id/*path' => 'public#image'
  match '/__fs__/*prefix' => 'public#file_store'
  match '/stylesheet/*path' => 'public#stylesheet', :as => :stylesheet

  match '/file/:action/*path' => 'public#index'

  match '/helper/sparklines/:action' => 'sparklines#index'

  match ':controller/service.wsdl' => '#wsdl'

  match '/module/:site_node/:controller/:action/*path' => '#index', :as => :module_action

  match '/paragraph/:site_node/:page_revision/:paragraph/*path' => 'page#paragraph', :as => :paragraph_action


  match '*path' => 'page#index', :as => :page
  root :to => 'page#index'
end


