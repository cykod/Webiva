# Copyright (C) 2009 Pascal Rettig.



class NodeEngine::BuiltinHandler < NodeEngine::HandlerBase

  def add_context(context)
    context[:ssl] = @engine.controller.request.ssl?
    context[:user_class] = @engine.user.user_class_id.to_s
    context[:language] = @engine.language
    context[:path_args] = @engine.path_args.join("/")
    context[:revision] = @engine.forced_revision if @engine.forced_revision
  end

  def before_page

    # Handle SSL Modifier
    unless @engine.mode == 'edit' 

      current_domain = controller.request.domain(10)

      ssl_switch =  (page[:ssl] && !controller.request.ssl?) || (!page[:ssl] && controller.request.ssl?)
      
      domain_switch = page[:domain] && current_domain != page[:domain]  && 
        current_domain != ("www." + page[:domain]) &&
        ( "www." + current_domain) !=  page[:domain]

      if ssl_switch || domain_switch
        dest_domain = page[:domain] ? page[:domain] : current_domain

        dest_http = page[:ssl] ? 'https://' : 'http://'

        output = SiteNodeEngine::RedirectOutput.new
        output.status = 'Redirect'
        output.redirect =  dest_http + dest_domain +  controller.request.request_uri         
        return output
      end
      

      # Now lets go through all the locks
      permitted = true
      if !engine.user.client_user? && page.locks.is_a?(Array) && page.locks.length > 0
        # If we got locks, Go through each lock backwards, and make sure we have access
        redirection = ''
        user_class = engine.user.user_profile
        page.locks.reverse_each do |lock|
          access = lock_access(lock, @engine.user)
          case access
            # If locked, set to not permitted and return false
          when :unlocked
            ''
            # If full, we don't need to check the rest
          when :full
            break
          else
            controller.session[:lock_lockout] = controller.request.request_uri
            permitted =false
            redirection=access
            break
            # Otherwise are ok with this lock, but need to check the rest
          end
        end
      end
      
      # no access, create a RedirectOutput, and redirect to the appropriate page
      if !permitted
        @output = SiteNodeEngine::RedirectOutput.new
        @output.status = 'Lock'
        @output.redirect = redirection
        
        return @output
      end
    end
  end

  protected
  
  def lock_access(lock,user)
    unless lock.is_a?(SiteNodeModifier)
      
      lock_id = lock['id']
      lock = SiteNodeModifier.new(lock)
      lock.id = lock_id
    end

    lock.modifier_data ||= {}
    lock.modifier_data.symbolize_keys!
    
    access = lock.access(user)
    
    return access unless access == :locked
    
    redirect= "/"
    if lock.modifier_data[:redirect] && lock.modifier_data[:redirect] != ''
      nd = SiteNode.find_by_id(lock.modifier_data[:redirect])
      redirect = nd.node_path if nd
    end
    
    redirect
  end 
     
end
