# Copyright (C) 2009 Pascal Rettig.



module SiteAuthorizationEngine


  module Controller

    def permit?(what,opts={})
      # make sure we're dealing with an array of roles
      what = [ what ] if !what.is_a?(Array)

      # Expand from list of roles to list of ids w/ role names
      expanded_roles = Role.expand_roles(what)
      myself.has_any_role?(expanded_roles)
    end
                

    def permit(what,opts={})

      if !permit?(what,opts)
        store_return_location
        redirect_to :controller => '/manage/access', :action => 'denied'
        false
      else
        if block_given?
          yield
          true
        else
          true
        end
      end
      
    end

    def self.included(mod)
      mod.extend(SiteAuthorizationEngine::ControllerClassMethods)
      mod.send(:helper_method,'permit?')
    end

  end
  
  module ControllerClassMethods

    # from authorization plugin - authorization.rb
    def permit(what,args={})
      filter_keys = [ :only, :except ]
      filter_args, eval_args = {}, {}
      if args.is_a? Hash
        filter_args.merge!( args.reject {|k,v| not filter_keys.include? k } ) 
        eval_args.merge!( args.reject {|k,v| filter_keys.include? k } ) 
      end
      
      append_before_filter(filter_args) do |controller|
        controller.permit(what,eval_args)
      end

    end
  end
  

  module Actor

    def has_all_roles?(roles)
      roles.each do |role|
        return false unless self.has_role?(role)
      end
      true
    end

    def has_any_roles?(roles)
      roles.each do |role|
        return true if(self.has_role?(role)) 
      end
      false
    end

    def has_role?(role,target=nil)
      self.role_ids.include?(Role.expand_role(role,target))
    end

    def has_role(role,target=nil,skip_save=false)
      obj = Role.role_item(role,target)
      if !self.roles.include?(obj)
        self.user_roles.create(:role => obj)
        self.roles.reload
        self.save unless skip_save
      end
    end

    def has_no_role(role,target=nil,skip_save=false)
      obj = Role.role_item(role,target)
      if user_role = self.user_roles.find_by_role_id(obj.id)
        user_role.destroy
        obj.destroy if obj.user_roles.empty?
        self.save unless skip_save
      end
    end

    def self.included(mod)
      mod.send(:has_many, :user_roles, :as => :authorized)
      mod.send(:has_many, :roles, :through => :user_roles)

      mod.extend(ActorClassMethods)
    end

  end

  module ActorClassMethods

  end


  module Target


    def self.included(mod) #:nodoc:
      mod.send(:has_many, :roles, :as => :authorizable)
      mod.extend(TargetClassMethods)
    end

    def access_role(name)
      obj = Role.role_item(name.to_s,self)
    end

    def user_roles(name)
      access_role(name).user_roles
    end

    def user_roles_display(name)
      user_roles(name).map(&:name)
      
    end
  end

  module TargetClassMethods

    def access_control(name)

      define_method("#{name}_granted?") do |usr|
        if self.send("#{name}?")
          usr.has_role?(name,self)
        else
          true
        end
      end

      define_method("#{name}_authorized") do
        user_roles(name)
      end

      define_method("#{name}_authorized=") do |val|
        user_roles = self.user_roles(name)
        user_roles.each { |ur| ur.destroy }
        val.each do |itm|
          if !itm['identifier'].blank?
            item = itm['identifier'].split("/")
            authorized = item[0].camelcase.constantize.find_by_id(item[1])
            if authorized
              authorized.has_role(name,self)
            end
          end
        end
      end
    end

  end

end
