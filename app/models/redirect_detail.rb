# Copyright (C) 2009 Pascal Rettig.

class RedirectDetail < DomainModel

  belongs_to :site_node
  belongs_to :redirect_site_node,:class_name => 'SiteNode'
  def destination
    if self.redirect_type == 'external'
      self.redirect_url
    elsif self.site_node
      self.redirect_site_node.node_path
    else
      '/'
    end
  end


  
  def validate_on_update
  	if redirect_type == 'site_node'
  		unless redirect_site_node_id
  			errors.add(:redirect_site_node_id,"Please select a redirection page")
  		end
  	elsif redirect_type == 'external' 
  		unless redirect_url
  			errors.add(:redirect_url,"Please enter a redirection url")
  		end
  	else
  		errors.add(:redirect_type,"Please select the redirection type")
  	end
  
  end
  
  has_options :redirect_type, [ [ 'A Different Page', 'site_node' ], ['An External URL','external' ]]

end
