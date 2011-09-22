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
      fields << ['tag_names', 'Tags'.t ]
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
      headings = fields.collect do |fld|
        fld[1]
      end

      if options[:fields] && options[:handlers_data]
        headings = headings + options[:fields].collect do |fld|
          info = UserSegment::FieldHandler.display_fields[fld.to_sym]
          info[:handler].field_heading(fld.to_sym)
        end
      end
      writer << headings
    end
    data = fields.collect do |fld|
      if fld[0]
        self.send(fld[0])
      else
        fld[2]
      end
    end

    if options[:fields] && options[:handlers_data]
      data = data + options[:fields].collect do |fld|
        info = UserSegment::FieldHandler.display_fields[fld.to_sym]
        info[:handler].field_output(self, options[:handlers_data][info[:handler].to_s], fld.to_sym)
      end
    end

    writer << data
  end



  module ClassMethods

   

# Return a list of available import fields for matching
  def import_fields #:nodoc:
    
    fields = [ [ 'email', 'Email'.t, ['email','e-mail' ], :field ],
      [ 'language', 'Language'.t, ['language' ], :field ],
      [ 'gender', 'Gender'.t, [ 'gender','sex' ], :special ],
      [ 'tags', 'Add Tags'.t, [ 'tags' ], :tags ],
      [ 'salutation','Salutation'.t,['salutation'],:field],
      [ 'introduction','Introduction'.t,['introduction'],:field],
      [ 'first_name', 'First Name'.t, ['first name'], :field ],
      [ 'last_name', 'Last Name'.t, ['last name'], :field ],
      [ 'middle_name','Middle Name'.t, ['middle name'], :field],
      [ 'suffix','Suffix'.t,['suffix'],:field],
      [ 'name', 'Full Name'.t, ['name'], :special ],
      [ 'referrer','Referrer'.t,['referrer'],:field],
      [ 'lead_source','Lead Source'.t,['lead source'],:field],
      [ 'username','Username'.t,['username'],:field],
      [ 'password', 'Password'.t, ['password'], :special ],
      [ 'cell_phone','Cell Phone'.t,['cell phone'],:field],
      [ 'remove_tags', 'Remove Tags'.t, [ 'tags' ], :remove_tags ],
#      [ 'domain_file_id', 'Image'.t, :special ],
      ['dob', 'Date of Birth'.t, ['date of birth','birth date'], :special ],
      ['vip_number', 'VIP Number'.t, ['vip number','vip'], :field ],
    ].collect do |fld|
      [ fld[0], fld[1], (fld[2] + fld[2].map { |nm| [nm.t,nm.gsub(" ",'')]}).flatten, fld[3] ]
    end
    
    # Add in address fields
    %w(home work billing).each do |address|
      adr_text = address.humanize
      %w(company phone fax address address_2 city state zip country).each do |field|
        if address == 'work' || field != 'company'
          human_field = adr_text + ' - ' + field.humanize
          fields << [ address + "_" + field, human_field.t, 
               [ human_field.downcase, human_field.downcase.t ] +
               (address == 'home' ? [ field.humanize.downcase, field.humanize.downcase.t ] : []),
          :address ]
	end
      end
    end
    
    fields
  end 
  
  
  def import_csv(filename,data,options={}) #:nodoc:
    actions = data[:actions]
    matches = data[:matches]

    deliminator = options[:deliminator]

    opts = options[:options]
    user_opts = opts[:user_options] || {}

    page = options[:page].to_i
    page_size = options[:page_size] || 500

    import = options[:import] || false

    page = 1 if page < 1

    reader_offset = nil
    reader_limit = nil
    unless import
      reader_offset = (page-1) * page_size
      reader_limit = reader_offset + page_size
    end

    entry_errors = []

    email_field = nil
    reader = nil

    file_fields = nil
    begin
      reader = FasterCSV.open(filename,"r",:col_sep => deliminator)
      file_fields = reader.shift
    rescue FasterCSV::MalformedCSVError=> e
      reader = FasterCSV.open(filename,"r",:col_sep => deliminator, :row_sep => ?\r)
      file_fields = reader.shift
    end
    fields = []

    user_fields = EndUser.import_fields
    if SiteModule.module_enabled?('user_profile')
      user_fields += UserProfileType.import_fields
    end
    
    segment = nil
    if import
      if opts[:user_list] == 'create'
        segment = UserSegment.create(:main_page => true, :segment_type => 'custom', :name => opts[:user_list_name], :order_by => 'created', :order_direction => 'DESC') unless opts[:user_list_name].blank?
      elsif ! opts[:user_list].blank?
        segment = UserSegment.find_by_id opts[:user_list].to_i
      end
    end

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
    uids = []

    opts[:all_tags] = opts[:all_tags].split(',')
    opts[:create_tags] = opts[:create_tags].split(',')
    opts[:create_tags] = nil if opts[:create_tags].empty?

    new_user_class = UserClass.find_by_id(opts[:user_class_id]) || UserClass.default_user_class

    finished = false
    row = nil
    while !finished && !reader.eof?
      entry_errors = []
      begin 
        row = reader.shift
      rescue Exception => e
        entry_errors << "Ignoring malformed row: " + e.to_s
        row = []
      end


      if(row.join.blank?)
        idx+=1
        next
      end

      if !reader_offset || idx >= reader_offset
        entry = EndUser.find_by_email(row[email_field]) unless row[email_field].blank?

        if import
          entry_addresses = {}

          entry_profiles = {}
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
              ( entry_method == :new && opts[:import_mode] == 'create' )
            fields.each do |fld|
              value = row[fld[1]].to_s
              if fld[4].to_sym == :field
                if fld[3] == 'email'
                  if !value.blank?
                    if value =~ RFC822::EmailAddress
                      entry_values[fld[3]] = value unless value.blank?
                    elsif value.split(',')[0].to_s.strip =~ RFC822::EmailAddress
                      entry_values[fld[3]] = value.split(',')[0].strip
                    end
                  end
                else
                  entry_values[fld[3]] = value unless value.blank?
                end
              elsif fld[4].to_sym == :address
                process_import_address(entry,entry_addresses,fld[3],value)
              elsif fld[4].to_sym == :tags
                extra_tags = value
              elsif fld[4].to_sym == :remove_tags
                remove_tags = value
              elsif fld[4].to_sym == :profile
                process_profile_import(entry,entry_profiles,fld[3],value)
              else
                process_import_field(entry,fld[3],value)
              end
            end

            entry.attributes = entry_values
            entry.admin_edit = true

            if entry.valid?
              entry_addresses.each do |key,adr|
                adr.save
                entry.send("#{key}=".to_sym,adr.id)
              end

              if user_opts.include?('vip') && entry.vip_number.blank?
                entry.vip_number = EndUser.generate_vip()
              end


              if(entry.save(false))
                uids << entry.id
                entry_addresses.each do |key,adr|
                  if adr.end_user_id != entry.id 
                    adr.update_attribute(:end_user_id,entry.id)
                  end
                end
                # add
                #

                if SiteModule.module_enabled?('user_profile')
                  if entry_profiles.length > 0
                    entry_profiles.each do |profile_id,values|
                      profile_entry = UserProfileEntry.fetch_entry(entry.id,profile_id.to_i)
                      content_model_entry  = profile_entry.content_model_entry
                      content_model_entry.attributes = values
                      content_model_entry.save
                    end
                  end
                end

                tags_to_add = opts[:all_tags]
                tags_to_add += opts[:create_tags] if opts[:create_tags] && entry_method == :new
                tags_to_add += extra_tags.split(',') unless extra_tags.blank?

                entry.tag tags_to_add unless tags_to_add.empty?

                if remove_tags
                  entry.reload unless tags_to_add.empty?
                  entry.tag_remove(remove_tags, :separator => ',')
                end
              end
            else
              entry_errors << [idx, entry.email.to_s + ":" + entry.errors.full_messages.join(",")]
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

      end

      # Exit if we are already over sample limit
      if reader_limit &&  idx >= reader_limit
        break;
      end
      idx+=1


      if block_given?
        yield 1,entry_errors
      end
    end
    reader.close

    segment.add_ids uids if segment

    if import
      return entry_errors
    else
      return fields, parsed_data
    end

  end


  def process_profile_import(entry,entry_profiles,field,value) #:nodoc:
    return if value.blank?
    content_model_field_cache = DataCache.local_cache('end_user_import_extension:content_model_field_cache') || {}
    if field =~ /user_profile_field_([0-9]+)_([0-9]+)/
      user_profile_type_id = $1.to_i
      user_profile_column_id = $2.to_i
      content_model_field_cache[user_profile_column_id] ||= ContentModelField.find_by_id(user_profile_column_id)


      if content_field = content_model_field_cache[user_profile_column_id]
        if !content_field.field.blank?
          entry_profiles[user_profile_type_id] ||= {}
          entry_profiles[user_profile_type_id][content_field.field] = value
        end
      end
    end
    DataCache.put_local_cache 'end_user_import_extension:content_model_field_cache', content_model_field_cache
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
     field_data = field.split("_")

    address = field_data[0]
    field = field_data[1..-1].join("_")
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
