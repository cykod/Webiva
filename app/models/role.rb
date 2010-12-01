# Copyright (C) 2009 Pascal Rettig.

class Role < DomainModel

  has_many :user_roles

  has_many :authorized, :through => :user_roles
  
  has_many :user_classes, :through => :user_roles, :source => :user_class,
  :conditions => "user_roles.authorized_type = 'UserClass'"

  has_many :access_tokens, :through => :user_roles, :source => :access_token,
  :conditions => "user_roles.authorized_type = 'AccessToken'"
  
  belongs_to :authorizable, :polymorphic => true

  validates_presence_of :name

  cached_content

  @@system_roles = %w(system_admin client_admin client_user)

  def self.user_classes(role_name)
    rl = self.find_by_name(role_name)
    return [] unless rl
    
    rl.user_classes
  end

  def self.authorized_options(editor=false)

    if editor.is_a?(Symbol)
      editor = [ ['--User---'.t,nil],false, ['--Editor--'.t,nil], true ]
    else
      editor = [ editor ? true : false ]
    end

    lst = []
    editor.each do |ed|
      if ed.is_a?(Array)
        lst += [ ed ]
      else
        lst += UserClass.find(:all,:conditions => ['editor = ?',ed],:order =>'name').map do |cls|
          ["Profile: %s" / cls.name, "user_class/" + cls.id.to_s]
        end

        lst += AccessToken.find(:all,
                                :conditions => ['editor = ?',ed],
                                :order =>'token_name').map do |tkn|
          [ "Access Token: %s" / tkn.token_name, "access_token/" + tkn.id.to_s ]
        end
      end
    end

    lst
  end

  def self.role_item(what,obj=nil)
     if !obj
       role = Role.find(:first,:conditions => ['name = ?  AND authorizable_type IS NULL AND authorizable_id IS NULL',what.to_s]) ||  Role.create(:name => what.to_s)
     else
      role = Role.find(:first,:conditions => ['name = ?  AND authorizable_type=? AND authorizable_id = ?',what.to_s,obj.class.to_s,obj.id]) || Role.create(:name => what.to_s, :authorizable => obj)
    end
  end

  
  ## TODO: cache all the standard roles 

  def self.expand_roles(what)

    cache = self.role_cache

    # If a role doesn't exist, doesn't mean we have it
    what.map do |elm|
      elm = elm.to_s
      if @@system_roles.include?(elm)
        elm
      else
        cache[elm]
      end
    end
  end

  def self.role_cache
    role_lookup = DataCache.local_cache('role_cache')
    if !role_lookup
      role_lookup = self.cache_fetch_list('role_cache') 
      DataCache.put_local_cache('role_cache',role_lookup) if role_lookup
    end

    if !role_lookup
      roles = Role.find(:all,:select => 'id,name',:conditions => 'authorizable_type IS NULL AND authorizable_id IS NULL')

      role_lookup = {}
      roles.each { |role| role_lookup[role.name] = role.id }

      DataCache.put_local_cache('role_cache',role_lookup)
      self.cache_put_list('role_cache',role_lookup)
    end

    role_lookup
  end

  def self.expand_role(what,obj=nil)
    # If it's a number, we're already expanded
    return what if what.is_a?(Integer)

    if !obj
      role_cache[what.to_s] || 0
    else
      role = Role.find(:first,:select => 'id',:conditions => ['name = ?  AND authorizable_type=? AND authorizable_id = ?',what.to_s,obj.class.to_s,obj.id])
      role ? role.id : 0
    end
  end

end
