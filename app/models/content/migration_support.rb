# Copyright (C) 2009 Pascal Rettig.


module Content::MigrationSupport  #:nodoc:

 def delete_table
   cClass = ContentMigrator.clone

   if self.table_name
     cClass.suppress_messages do
       cClass.update_up(<<-CODE)
         drop_table :#{self.table_name} do |t|
         end
       CODE

       cClass.migrate_domain(Domain.find(DomainModel.active_domain_id))
     end
   end
  end
  
  def create_table
    
    # Need to find a DB table name to use
    
    # get a prefix from the name
    # replace spaces with underscores, but get rid of everything else
    table_name_prefix = "cms_" + self.name.downcase.gsub(/[ _\-]+/,"_").gsub(/[^a-z+0-9_]/,"").gsub(/__+/,"_")[0..24]
    # use an index if necessary, (e.g. blog_2, etc if necessary )
    table_name_index = 1
    
    while ContentModel.find(:first,:conditions => ['table_name = ?',(table_name_prefix + (table_name_index > 1 ? table_name_index.to_s : '')).pluralize ])
      table_name_index += 1
    end
    
    self.table_name = (table_name_prefix + (table_name_index > 1 ? "_" + table_name_index.to_s : '')).pluralize
    
    self.content_type.update_attribute(:content_type,self.table_name.classify)
    
    cClass = ContentMigrator.clone
    cClass.suppress_messages do
      cClass.update_up(<<-CODE)
        create_table :#{table_name} do |t|
        end
      CODE

      cClass.migrate_domain(Domain.find(DomainModel.active_domain_id))
    end
    
    self.save
  end
  
  # Update the table with the field data in field data
  # If this is coming from a web edit (field_data is a hash, and field order is an array)
  # We need transform field data to an array
  def update_table(field_data,deleted_fields = [])
    migration_code = ''
    
    if deleted_fields
      deleted_fields.each do |fld| 
        field = self.content_model_fields.find(fld)
        if field
          content_field = ContentModel.content_field(field.field_module,field.field_type)
          if content_field[:representation].is_a?(Array)
            content_field[:representation].each do |rep|
              migration_code += "remove_column  :#{self.table_name}, :#{field.field}#{rep[0].blank? ? '' : "_#{rep[0]}"}\n"
            end
            # Handle regular fields
          elsif content_field[:representation] && content_field[:representation] != :none
            migration_options = content_field[:migration_options] ? ", " + content_field[:migration_options] : ''
            migration_code += "remove_column  :#{self.table_name}, :#{field.field}\n"
          end
          field.destroy
        end
      end
    end
    
    self.class.logger.warn(field_data.inspect)
    #      ContentModelField.transaction do
    field_data.each_with_index do |field,idx|
      field.symbolize_keys!

      content_field = nil 

      # If we're not a hash or a non-field item (group, label, etc)
      if(!field.is_a?(Hash))
        # Nothing
        # find the field row if we have an id
      elsif(field[:id]) 
        field_row = self.content_model_fields.find(field[:id])
        field_row.field_options ||= {}
        self.class.logger.warn('FIELD ROW')
        self.class.logger.warn(field_row.inspect)
        content_field = ContentModel.content_field(field_row.field_module,field_row.field_type)
        
        next unless content_field
        
        # Otherwise, we need to create migration code
      else 
        field_row = self.content_model_fields.build()
        field_row.field_options = {}
        
        content_field = ContentModel.content_field(field[:field_module],field[:field_type])
        next unless content_field
        
        
        field_name_prefix = field[:name].downcase.gsub(/[^a-z0-9]+/,"_")[0..20].singularize
        # use an index if necessary, (e.g. blog_2, etc if necessary )
        field_name_index = 1

        @reserved_names ||= %w(id accept callback categorie action attributes application connection database dispatcher display drive errors format host key layout load link new, notify open public quote render request records responses save scope send session system template test timeout to_s type visits)
        if @reserved_names.include?(field_name_prefix)
          field_name_prefix = "fld_#{field_name_prefix}"
        end
        field_name_try = field_name_prefix
        
        while self.content_model_fields.find(:first,:conditions => [ 'field=?',field_name_try ] )
          field_name_index += 1
          field_name_try = field_name_prefix + field_name_index.to_s
        end
        
        
        raise 'Error' unless content_field
        field_row.field_type = field[:field_type].to_s
        field_row.field_module = field[:field_module].to_s
        
        if content_field[:relation]
          field_row.field = field_name_try + "_id"
          if content_field[:relation] == :plural
            field_row.field_options['relation_singular'] = field_name_try
            field_row.field_options['relation_name'] = field_name_try.pluralize
          else
            field_row.field_options['relation_name'] = field_name_try
          end
        else
          field_row.field = field_name_try
        end
        
        
        # Handle fields with more than field
        if content_field[:representation].is_a?(Array)
          content_field[:representation].each do |rep|
            migration_code += "add_column  :#{self.table_name}, :#{field_row.field}#{rep[0].blank? ? '' : "_#{rep[0]}"}, :#{rep[1]}\n"
          end
          # Handle regular fields
        elsif content_field[:representation] && content_field[:representation] != :none
          migration_options = content_field[:migration_options] ? ", " + content_field[:migration_options] : ''
          migration_code += "add_column  :#{self.table_name}, :#{field_row.field}, :#{content_field[:representation]}#{migration_options}\n"
          migration_code += "add_index   :#{self.table_name}, :#{field_row.field}, :name => '#{field_row.field}_index'\n" if content_field[:index]
        end
        
        
        
      end
      
      if field_row && content_field
        field_row.field_options.merge!(field_row.set_field_options(field[:field_options]))
        
        field_row.position = idx + 1;
        field_row.name = field[:name]
        field_row.description = field[:description]
        
        field_row.save
        
        self.class.logger.warn(field_row.inspect)
      end
      
    end
    #      end
    
    cClass = ContentMigrator.clone
    cClass.suppress_messages do
      cClass.update_up(migration_code)
      cClass.migrate_domain(Domain.find(DomainModel.active_domain_id))
    end
  end
  
end
