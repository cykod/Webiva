# Copyright (C) 2009 Pascal Rettig.

require 'csv'


module Content::ImportSupport

def export_xml(output,options = {}) 
  
    output.puts '<?xml version="1.0"?>'
    output.puts '<entries>'
    self.content_model.find(:all,options).each_with_index do |row,idx|
      output.puts(row.to_xml(:skip_instruct => true, :root => 'entry', :indent => 1))
      if block_given?
	yield idx+1
      end
    end
    output.puts '</entries>'
  end
  
  def export_yaml(output,options = {})
     output.write(content_model.find(:all,options).map { |entry| entry.attributes }.to_yaml)
  end
  
  def export_csv(writer,options = {})
     fields = [ ContentModelField.new(:name => 'Identifier', :field => 'id')] + self.content_model_fields
  
     writer << fields.collect do |fld|
      fld.name
     end
     self.content_model.find(:all,options).each_with_index do |row,idx|
    	writer << fields.collect do |fld|
	      fld.text_value(row)
    	end
     end
  end
  
  def import_csv(filename,data,options={})
    actions = data[:actions]
    matches = data[:matches]
    create = data[:create]
    
    deliminator = options[:deliminator]

    identifiers = data[:identifiers] || {}
    model_fields = self.all_fields 
    page = options[:page].to_i
    page_size = options[:page_size] || 50
    
    import = options[:import] || false
    
    page = 1 if page < 1
    
    unless import
      reader_offset = (page-1) * page_size
      reader_limit = reader_offset + page_size
    end
    
    entry_errors = []
    
    invert_matches = matches.invert
    reader = CSV.open(filename,"r",deliminator)
    file_fields = reader.shift
    fields = []
    file_fields.each_with_index do |fld,idx|
      if actions[idx.to_s] == 'c'
        # Only allow creation of fields,
        # If not actually importing
        if import
          raise 'Cant create fields during import'
        else
	       fields << [fld.to_s,idx,'new',create[idx.to_s]]
	      end
      elsif actions[idx.to_s] == 'm'
        match = model_fields.detect do |mdl_fld|
                  mdl_fld.field == matches[idx.to_s]
        end
        fields << [match.name,idx,'match',match.field]
      end
    end
    
    matched_identifiers = []
    matched_conditions = []
    identifiers.each do |idx,val|
      if(actions[idx] == 'm')
        match = model_fields.detect do |clb|
                  clb.field == matches[idx]
        end
        matched_identifiers << [ idx.to_i, match.field ]
        matched_conditions << "`#{match.field}` = ?"
      end
    end
    matched_conditions = matched_conditions.join(" OR ")
    
    mdl = self.content_model
    parsed_data = []
    idx = 0
    reader.each do |row|
      entry_errors = []

      if row.join.blank?
        idx+=1
        next
      end
      
      if !reader_offset || idx >= reader_offset
	      existing_entry = nil
	      if matched_identifiers.length > 0
	       matched_values = matched_identifiers.map do |ident|
	         row[ident[0]]
	       end
	       existing_entry = mdl.find(:first, :conditions => [ matched_conditions ] + matched_values)
	      end
	      act = existing_entry ? existing_entry.id : 'c'
	      # If we are doing an import,
	      # All fields should be 'm'
	      if import
	       entry_values = {}
	       fields.each do |fld|
	          entry_values[fld[3]] = row[fld[1]].to_s.strip
	        end
	        
	        if existing_entry 
	         if !existing_entry.update_attributes(entry_values)
	           entry_errors << [idx, !existing_entry.errors ]
	         end
	        else
	         if !(new_entry = mdl.create(entry_values))
	           entry_errors << [idx, new_entry.errors ]
	         end
	        end
	      else
	        parsed_data << [ act ] + fields.collect do |fld|
	          row[fld[1]].to_s
	        end
	      end
	
	      if block_given?
	       yield 1,entry_errors
	      end
            end
      
      # Exit if we are already over sample limit
      if reader_limit &&  idx >= reader_limit
        break;
      end
      idx+=1
    end
    reader.close
    
    if import
      return entry_errors
    else
      return fields, parsed_data
    end
  
  end
  
 # Add in the matching fields options to the content model class
 def self.append_features(mod)
    super
    mod.send :has_options, :matching_fields, 
       [ ['Do not match field',nil],
         ['Email','end_user.email'],
         ['First Name','end_user.first_name'],
         ['Last Name','end_user.last_name'],
         ['Middle Name','end_user.middle_name'],
         ['Phone','address.phone'],
         ['Address - Street Number','address.address'],
         ['Address - line 2','address.address_2'],
         ['Address - City','address.city'],
         ['Address - State','address.state'],
         ['Address - Zip','address.zip'],
         ['Additional Data','data']
        ]
    end
    
end
