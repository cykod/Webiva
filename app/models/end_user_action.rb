# Copyright (C) 2009 Pascal Rettig.

=begin rdoc
EndUserAction's log actions that users have taken in the system, these are logged
by category and date / time and can be used to segment users into different groups
(TODO)

EndUserAction's are normally not created manually, but are accessed through a EndUser
object with the EndUser#action or EndUser#custom_action commands.

Actions are registered with the ModuleController#register_action method in a module's
admin controller. Registering actions allows extra information such as a custom description 
as well as link that contains more details to be added. For example:

        register_action '/shop/processor/item', 
             :description => 'Item Purchase', 
             :controller => '/shop/catalog', 
             :action => 'edit', :level => 5, :path => :target


### Levels 

The different levels are as follows:
["Admin Action (0)]
  Any actions taken by an administrator
[Data Action (1)]
  Additional data associated with a user can be stored here
[Access Action (2)]
  Any actions that log login / logout / access denied
[User Actions (3)]
  Any non-conversion actions the user takes on their own behalf
[Informational (4)]
  Informational actions, such as notes, admin notes, legacy user actions from other systems / etc
[Conversion (5)]
  Any conversions - purchases/etc             


###  Example actions

 myself.action("/editor/auth/login')
 myself.action("/shop/processor/order",:target => @order)
 myself.action("/shop/processor/item", :target => @product)
 myself.custom_action("legacy_purchase","User did this...") 
 
=end
class EndUserAction < DomainModel

  belongs_to :end_user
  belongs_to :admin_user, :class_name => 'EndUser',:foreign_key => 'admin_user_id'
  belongs_to :target,:polymorphic => true
  
  validates_presence_of :end_user_id,:level,:renderer,:action
 

   has_options :level, 
           [ [ "Admin Action (0)", 0 ],
            [ "Data Action (1)",1],
            [ "Access Action (2)",2],
            [ "User Action (3)",3],
            [ "Informational (4)",4],
            [ "Conversion (5)",5 ] ]
            

  # Log an action on a user
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
  
  # Log a custom action on a user - there's no registered action associated with this
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

  # reteurn the full action path
  def action_path
    "/#{self.renderer}/#{self.action}"
  end

  # generate a textual description of the action, either by pulling a handler
  # or by humanizing the renderer and action
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
  
  def self.split_name(action_path) #:nodoc:
    if action_path =~ /^\/(.*)\/([^\/]+)$/
      [ $1,$2 ]
    else
      [ nil,nil ]
    end
  end
  

end
