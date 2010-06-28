# Copyright (C) 2009 Pascal Rettig.

class MigrationHandlerWorker < Workling::Base #:nodoc:all
  
  def do_work(args)
  
    domain = Domain.find_by_id(args[:domain_id])
    return false unless domain
    
    # Don't Save connection
    DomainModel.activate_domain(domain.get_info,'migrator',false)
    
    
    DomainModel.logger = logger
  
    # This method is called in it's own new thread when you
    # call new worker. args is set to :args
    action =args[:action]
    
    Workling.return.set(args[:uid],false)
    content = ContentModel.find(args[:content_model_id]) 
    
    print "Got Action: #{action.to_s}\n"
    case action
    when 'create_table':
      print "Creating Table\n"
      content.create_table
    when 'update_table':
      print "Updating Table\n"
      content.update_table(args[:fields],args[:field_deletions])
    when 'destroy_table':
      content.delete_table
      content.destroy
    end
    Workling.return.set(args[:uid],true)
  end

end
