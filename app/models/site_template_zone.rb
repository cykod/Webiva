# Copyright (C) 2009 Pascal Rettig.

class SiteTemplateZone < DomainModel #:nodoc:all

  acts_as_list :scope => :site_template_id, :column => 'position'

  belongs_to :site_templates


  def self.get_template_zone_by_name(site_template,name,*args) 

     self.find_merged_push(args,:first,:conditions => ['site_template_id=? AND name=?',
                                                  site_template.id,name])
    
  end
end
