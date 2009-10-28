# Copyright (C) 2009 Pascal Rettig.

class ContentModelType < DomainModel
  self.abstract_class = true

  def self.select_options(options = {})
       self.find(:all,options).collect { |itm| [ itm.identifier_name, itm.id ] }
  end
  
  def after_save
    #
  end

  def after_destroy
    self.connection.execute("DELETE FROM content_relations WHERE content_model_id=" + quote_value(self.content_model_id) + "  AND entry_id=" + quote_value(self.id))
  end
  
  
  def self.human_name
    'Content Model'
  end  
  
  def self.human_attribute_name(attribute)
    attribute.to_s.humanize
  end

  def self.set_class_name(val)
    sing = class << self; self; end
    sing.send(:define_method, :class_name) do
      val
    end
  end
  
  def self.self_and_descendants_from_active_record
    [ ContentModelType ]
  end

  def self.has_through_relations(model_field)
    field_name = model_field.field
    class_name =  model_field.field_options['relation_class']
    target_relation_name = model_field.field_options['relation_name']
    target_relation_singular = model_field.field_options['relation_singular']

    relations_name = "content_relations_#{field_name}"
    has_many relations_name, :conditions => "content_model_id = #{self.quote_value(model_field.content_model_id)} AND content_model_field_id=#{self.quote_value(model_field.id)}", :as => :entry, :class_name => 'ContentRelation'

    has_many "#{target_relation_name}_dbs", :through => relations_name,
    :source => :relation,
    :source_type =>class_name


    alias_method "old_#{target_relation_singular}_ids", "#{target_relation_name}_db_ids"
    
    # Now customized set through connection stuff
    class_eval( <<-EOF)

    def #{target_relation_name}
      if  @#{relations_name}_cache
        #{class_name}.find(:all,:conditions => { :id => @#{relations_name}_cache }  )
      else
         #{target_relation_name}_dbs
      end
    end

    def #{target_relation_singular}_ids
      if @#{relations_name}_cache
        @#{relations_name}_cache.map { |elm| elm.blank? ? nil : elm.to_i }.compact
      else
        @old_#{target_relation_singular}_ids_cache ||=  old_#{target_relation_singular}_ids
      end
    end

    def #{target_relation_singular}_ids=(val)
      @#{relations_name}_cache = val
    end

    def #{target_relation_name}_after_save
      if @#{relations_name}_cache 
        set_content_through_collection(#{model_field.content_model_id},#{model_field.id},"#{class_name}",:"#{relations_name}", @#{relations_name}_cache)
      end
    end
EOF

    after_save "#{target_relation_name}_after_save"
  end

  def  set_content_through_collection(content_model_id,model_field_id,class_name,relation_name,ids)

    ids ||= []
    ids = ids.find_all { |elm| !elm.blank? }.collect { |elm| elm.to_i }

    current_collection = self.send(relation_name)

    # Remove the elements no longer in the ids or of the wrong relation_type
    current_collection.find_all do |cur_elm|
      !ids.include?(cur_elm.relation_id) || cur_elm.relation_type != class_name
    end.each { |elm| elm.destroy}

     # find the elements to add
    ids.each do |cur_id|
      elm = current_collection.detect { |elm| elm.relation_id == cur_id && elm.relation_type == class_name }
      current_collection.create(:content_model_id => content_model_id,
                                :content_model_field_id => model_field_id,
                                :relation_type => class_name,
                                :relation_id => cur_id) unless elm
    end

  end
  
end
