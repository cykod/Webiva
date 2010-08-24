ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.
  
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  # map.connect '', :controller => "welcome"
  map.language_link '/view/:language/*path',
              :controller => 'page',
              :action => 'view'
              
  map.connect '/website',
    :controller => 'manage/access',
    :action => 'login'

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



  map.connect '/website/:controller/:action/*path'

  map.connect "/file/:action/*path",
              :controller => "public"
  
  map.connect "/helper/sparklines/:action",
              :controller => 'sparklines'
  

  begin
    Dir.glob("#{RAILS_ROOT}/vendor/modules/[a-z]*") do |file|
      if file =~ /\/([a-z_-]+)\/{0,1}$/
        mod_name = $1
        if File.exists?(file + "/routes.rb")
          require file + "/routes.rb"
          cls = mod_name.classify.constantize 
          cls.send('routes',map) if cls.respond_to?('routes')
          if cls.respond_to?('domain_routes')
            
            domains = DomainRoute.find(:all,:conditions => { :module_name => mod_name }, :include => :domain )
            domains.each do |dmn|
              cls.send('domain_routes',map,dmn.domain.name) 
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

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'

  
  
  map.module_action "/module/:site_node/:controller/:action/*path"
  
  # Example Application Route
  #map.connect "/fun/:action/:id",
  #	      :controller => '/example/app_example'

    
  map.paragraph_action '/paragraph/:site_node/:page_revision/:paragraph/*path',
              :controller => 'page',
              :action => 'paragraph'
  
  map.page '*path',
              :controller => 'page',
              :action => 'index'

  map.connect '', :controller => 'page',
                  :action => 'index'      

end
