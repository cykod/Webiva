# Copyright (C) 2009 Pascal Rettig.

module ModelExtension::EndUserImportExtension

  
  def export_csv(writer,options = {}) #:nodoc:
    fields = [ ['email', 'Email'.t ],
               ['first_name', 'First name'.t ],
               ['last_name', 'Last name'.t ],
               ['language', 'Language'.t ],
               ['dob', 'Date of Birth'.t ],
               ['gender', 'Gender'.t ],
               ['user_level', 'User Level'.t ],
               ['source', 'Source'.t ]
              ]
    opts = options.delete(:include) ||  []
    if opts.include?('vip')
      fields << [ 'vip_number', 'VIP Number'.t ]
    end
    if opts.include?('tags')
      fields << ['tag_cache_tags', 'Tags'.t ]
    end
    
    
    address_objs = [ 'address', 'billing_address', 'work_address' ]
    
    %w(home billing work).each_with_index do |address,idx|
      if opts.include?(address)
        adr_obj = self.send(address_objs[idx])
	adr_text = address.humanize
	%w(company phone fax address city state zip country).each do |field|
	  if address == 'work' || field != 'company'
	    fields << [ nil, (adr_text + ' - ' + field.humanize).t, adr_obj ? adr_obj.send(field) : nil ]
	  end
	end
      end
    end    
    
    if options[:header]
      writer << fields.collect do |fld|
        fld[1]
      end
    end
    writer << fields.collect do |fld|
      if fld[0]
        self.send(fld[0])
      else
        fld[2]
      end
    end
  end



  module ClassMethods

   

# Return a list of available import fields for matching
  def import_fields #:nodoc:
    
    fields = [ [ 'email', 'Email'.t, ['email','e-mail' ], :field ],
      [ 'language', 'Language'.t, ['language' ], :field ],
      [ 'gender', 'Gender'.t, [ 'gender','sex' ], :special ],
      [ 'tags', 'Add Tags'.t, [ 'tags' ], :tags ],
      [ 'first_name', 'First Name'.t, ['first name'], :field ],
      [ 'last_name', 'Last Name'.t, ['last name'], :field ],
      [ 'name', 'Full Name'.t, ['name'], :special ],
      [ 'password', 'Password'.t, ['password'], :special ],
      [ 'remove_tags', 'Remove Tags'.t, [ 'tags' ], :tags ],
#      [ 'domain_file_id', 'Image'.t, :special ],
      ['dob', 'Date of Birth'.t, ['date of birth','birth date'], :special ],
      ['vip_number', 'VIP Number'.t, ['vip number','vip'], :field ],
    ].collect do |fld|
      [ fld[0], fld[1], fld[2] + fld[2].collect { |nm| nm.t }, fld[3] ]
    end
    
    # Add in address fields
    %w(work home billing).each do |address|
      adr_text = address.humanize
      %w(company phone fax address city state zip country).each do |field|
        if address == 'work' || field != 'company'
          human_field = adr_text + ' - ' + field.humanize
          fields << [ address + "_" + field, human_field.t, [ human_field.downcase, human_field.downcase.t ], :address ]
	end
      end
    end
    
    fields
  end 
  
  
  def import_csv(filename,data,options={}) #:nodoc:
    actions = data[:actions]
    matches = data[:matches]
    create = data[:create]

    deliminator = options[:deliminator]
    
    
    opts = options[:options]
    user_opts = opts[:user_options] || {}
    
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
    email_field = nil
    reader = CSV.open(filename,"r",deliminator)
    file_fields = reader.shift
    fields = []
    
    user_fields = EndUser.import_fields
    
    file_fields.each_with_index do |fld,idx|
      if actions[idx.to_s] == 'm'
        match = user_fields.detect do |user_fld|
          user_fld[0] == matches[idx.to_s]
        end
        if match
          fields << [match[1],idx,'match',match[0],match[3]]
          if match[0] == 'email'
            email_field = idx
          end
	end
      end
    end
    
    parsed_data = []
    idx = 0
    
    opts[:all_tags] ||= ''
    opts[:create_tags] ||= ''
    
    new_user_class = UserClass.find_by_id(opts[:user_class_id]) || UserClass.default_user_class
    reader.each do |row|

      if(row.join.blank?)
        idx+=1
        next
      end
      
      entry_errors = []
      if !reader_offset || idx >= reader_offset
	entry = EndUser.find_by_email(row[email_field]) unless row[email_field].blank?
	
	if import
	 entry_addresses = {}
	 
	 entry_values = {}
	 entry_method = :update
	 unless entry
	   entry_method = :new
	   entry = EndUser.new(:user_class_id => new_user_class.id, :source => 'import')
	 end

	 
	 extra_tags = nil
	 remove_tags = nil
	 
	 if opts[:import_mode] == 'normal' ||
	    ( entry_method == :update  && opts[:import_mode] == 'update' ) ||
	    ( entry_method == :create && opts[:import_mode] == 'create' )
	  fields.each do |fld|
	      value = row[fld[1]].to_s
	      if fld[4].to_sym == :field
		entry_values[fld[3]] = value
	      elsif fld[4].to_sym == :address
		process_import_address(entry,entry_addresses,fld[3],value)
	      elsif fld[4].to_sym == :tags
	        extra_tags = value
	      elsif fld[4].to_sym == :remove_tags
	         remove_tags = value
	      else
		process_import_field(entry,fld[3],value)
	      end
	    end
	    
	    entry.attributes = entry_values
	    entry.valid?

            if true # skip validation, allow no email address
	      entry_addresses.each do |key,adr|
		adr.save
		entry.send("#{key}=".to_sym,adr.id)
	      end

              if user_opts.include?('vip') &&  entry.vip_number.blank?
                entry.vip_number = EndUser.generate_vip()
              end

	      
	      if(entry.save(false))
		entry_addresses.each do |key,adr|
		  if adr.end_user_id != entry.id 
		    adr.update_attribute(:end_user_id,entry.id)
		  end
		end
		# add
		
		
		if !opts[:all_tags].empty?
		  entry.tag_names_add(opts[:all_tags])
		end
		# Add any create tags
		if !opts[:create_tags].empty? && entry_method == :new
		  entry.tag_names_add(opts[:create_tags])
		end

		if extra_tags
		  entry.tag_names_add(extra_tags)
		end
		
		if remove_tags
		  entry.tag_remove(remove_tags, :separator => ',')
		end

	      end
	    else
	     entry_errors << [idx, entry.errors ]
	    end
	  end
	else
	  act = entry ? 'm' : 'c'
	  act = 's' if act == 'm' && opts[:import_mode] == 'create'
	  act = 's' if act == 'c' && opts[:import_mode] == 'update'
	  
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
  


 
  def process_import_field(entry,field,value) #:nodoc:
    case field
    when 'gender':
      if ['m','male','m'.t,'male'.t].include?(value.to_s.downcase)
        entry.gender = 'm'
      elsif ['f','female','f'.t,'female'.t].include?(value.to_s.downcase)
        entry.gender = 'f'
      end
    when 'password':
      entry.password = value
      entry.password_confirmation = value
      entry.registered = true
    when 'name':
      name = value.split(" ")
      if name.length > 1
        entry.last_name = name[-1]
        entry.first_name = name[0..-2].join(" ")
      else
        entry.first_name = ''
        entry.last_name = name[0]
      end
    when 'dob':
      entry.dob = value
    end
  end
  
  def process_import_address(entry,entry_addresses,field,value) #:nodoc:
    address,field = field.split("_")
    adr = case address
      when 'work':
	entry_addresses['work_address_id'] ||= entry.work_address || EndUserAddress.new(:address_name => 'Default Work Address'.t )
      when 'home':
	entry_addresses['address_id'] ||= entry.address || EndUserAddress.new(:address_name => 'Default Address'.t )
      when 'billing':
        entry_addresses['billing_address_id'] ||= entry.billing_address || EndUserAddress.new(:address_name => 'Default Billing Address'.t )
    end
    
    adr.send("#{field}=".to_sym,value)
  end

  end



    def self.append_features(mod) #:nodoc:
      super
      mod.extend ModelExtension::EndUserImportExtension::ClassMethods
    end

end
