# Copyright (C) 2009 Pascal Rettig.

class ContentModelType < DomainModel
  self.abstract_class = true

  def self.select_options(options = {})
       self.find(:all,options).collect { |itm| [ itm.identifier_name, itm.id ] }
  end
  
  def after_save
    #
  end
  
  def self.human_name
    'Content Model'
  end  
  
  def self.human_attribute_name(attribute)
    attribute.to_s.humanize
  end
           
  def self.self_and_descendants_from_active_record
    [ ContentModelType ]
  end
  
end
