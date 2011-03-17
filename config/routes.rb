Webiva::Application.routes.draw do |map|
  match '/view/:language/*path' => 'page#view', :as => :language_link
  match '/website' => 'manage/access#login'

  match '/mailing/view/:campaign_hash/:queue_hash' => 'campaigns#view'
  match '/mailing/image/:campaign_hash/:queue_hash' => 'campaigns#image'
  match '/mailing/link/:campaign_hash/:link_hash/:queue_hash' => 'campaigns#link'

  match '/system/storage/:domain_id/*path' => 'public#image'
  match '/__fs__/*prefix' => 'public#file_store'
  match '/simple_captcha/:action' => 'simple_captcha#index', :as => :simple_captcha

  match '/website/:controller(/:action(/*path))'

  map.connect '/webalytics',
    :controller => 'page', :action => 'webalytics'

  map.connect '/mailing/view/:campaign_hash/:queue_hash',
    :controller => 'campaigns', :action => 'view'
  map.connect '/mailing/image/:campaign_hash/:queue_hash',
    :controller => 'campaigns', :action => 'image'
  map.connect '/mailing/link/:campaign_hash/:link_hash/:queue_hash',
    :controller => 'campaigns', :action =>  'link'
  
  map.connect '/system/storage/:domain_id/*path',
    :controller => 'public', :action => 'image'
  map.connect '/__fs__/*prefix', :controller => 'public', :action => 'file_store'
    
  map.stylesheet '/stylesheet/*path', :controller => 'public', :action => 'stylesheet'

  match '/file/:action/*path' => 'public#index'

  match '/helper/sparklines/:action' => 'sparklines#index'

  match ':controller/service.wsdl' => '#wsdl'

  match '/module/:site_node/:controller/:action/*path' => '#index', :as => :module_action

  match '/paragraph/:site_node/:page_revision/:paragraph/*path' => 'page#paragraph', :as => :paragraph_action

  begin
    Dir.glob("#{Rails.root}/vendor/modules/[a-z]*") do |file|
      if file =~ /\/([a-z_-]+)\/{0,1}$/
        mod_name = $1
        if File.exists?(file + "/routes.rb")
          require file + "/routes.rb"
          cls = mod_name.classify.constantize 
          cls.send('routes',self) if cls.respond_to?('routes')
          if cls.respond_to?('domain_routes')
            domains = DomainRoute.find(:all,:conditions => { :module_name => mod_name }, :include => :domain )
            domains.each do |dmn|
              cls.send('domain_routes',self,dmn.domain.name) 
            end
          end
          
        end
      end
    end  
  rescue Exception => e
    # For all the domain routes, we need the domain routes table to exist,
    # which may not be the case - just fail silently if there's a problem
    # TODO: output some sort of log message.
    
  end

  match '*path' => 'page#index', :as => :page
  root :to => 'page#index'
end


