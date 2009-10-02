# Copyright (C) 2009 Pascal Rettig.



class EndUserAction < DomainModel

  belongs_to :end_user
  belongs_to :admin_user, :class_name => 'EndUser',:foreign_key => 'admin_user_id'
  belongs_to :target,:polymorphic => true
  
  validates_presence_of :end_user_id,:level,:renderer,:action
  
#      t.integer :end_user_id
#      t.integer :admin_user_id
#      t.integer :level, :default => 1 #0-admin, #1 - data, #2-login/access,  #3-action, #4 - information,  #5-conversion
#      t.datetime :created_at    
#      t.datetime :action_at
#      t.string :target_type 
#      t.integer :target_id
#      t.boolean :custom,:default => false
#      t.string :renderer # beginning of the path
#      t.string :action # end of the action path
#      t.string :path # path to send to the detail page
#      t.string :identifier # Additional identifier besides target
#  
# Example Actions:
# myself.action("/editor/auth/login')
# myself.action("/shop/processor/order",:target => @order)
# myself.action("/shop/processor/item", :target => @product)
# myself.custom_action("legacy_purchase","User did this...") 

   has_options :level, 
           [ [ "Admin Action (0)", 0 ],
            [ "Data Action (1)",1],
            [ "Access Action (2)",2],
            [ "User Action (3)",3],
            [ "Informational (4)",4],
            [ "Conversion (5)",5 ] ]
            

    
  def self.log_action(user,action_path,opts={})
    act = DomainModel.get_handlers(:action,action_path.to_sym)[0]
    opts=opts.clone.symbolize_keys!
    opts=opts.slice(:admin_user_id,:admin_user,:level,:action_at,:target,:target_type,:target_id,:identifier,:path)
    
    # Get some extra data into the object
    if act && act = act[1]
      # Pull the path from the target if necessary
      opts[:path] = opts[:target].id.to_s if act[:path] && opts[:target] && opts[:path] == :target
      opts[:level] ||= act[:level] if act[:level]
    end
    opts[:action_at] ||= Time.now # Set the action time to now if we don't have a time
    opts[:end_user_id] = user.id # set the user id from the user
    
    opts[:renderer],opts[:action] = split_name(action_path)
    self.create(opts)
  end
  
  def self.log_custom_action(user,action_name,identifier,opts={})
    opts=opts.clone.symbolize_keys!
    opts=opts.slice(:admin_user_id,:admin_user,:level,:action_at)
    
    opts[:action_at] ||= Time.now # Set the action time to now if we don't have a time
    
    opts.merge!({ :end_user_id => user.id, # set the user id from the user
                  :custom => true,
                  :renderer => 'custom',
                  :action => action_name,
                  :identifier => identifier })    
    self.create(opts)  
  end


  
  #0-admin, #1 - data, #2-login/access,  #3-action, #4 - information,  #5-conversion  
  
  # register_action '/editor/auth/login', :description => 'Logged in'
  # register_action '/shop/processor/order', :description => 'Purchase', :controller => '/shop/manage', :action => 'view', :level => 4, :path => :target
  # register_action '/shop/processor/item', :description => 'Item Purchase', :controller => '/shop/catalog', :action => 'edit', :level => 4, :path => :target

  def action_path
    "/#{self.renderer}/#{self.action}"
  end

  def description
    act = DomainModel.get_handlers(:action,self.action_path.to_sym)[0]
    act = act[1] if act
    if act && act[:description] 
      act[:description]
    else
      self.renderer.gsub("/"," ").humanize + " " + self.action.humanize
    end
  end

  private
  
  def self.split_name(action_path)
    if action_path =~ /^\/(.*)\/([^\/]+)$/
      [ $1,$2 ]
    else
      [ nil,nil ]
    end
  end
  

end
