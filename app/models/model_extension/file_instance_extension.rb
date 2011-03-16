# Copyright (C) 2009 Pascal Rettig.


# FileInstance extension for DomainModel HTML Outputing fields
#
# process_file_instance :column, :column_html
# also adds in has_many :domain_file_instances, :polymorphic => true, :as => target
# adds in before_save for a function that processes column into column_html 
# saves the ID's of the affected file_ids into a instance variable
# user can also override this function to do additional processing work
# adds in after_save 
# saves the ID's of the affected files from the processing into the database
# Does db queries directly and does not instantiate the DomainFileInstance 
# Apply content filter does the same thing, exxcepts it will apply one
# of the system content filters as well
module ModelExtension::FileInstanceExtension

  module ClassMethods

    # Will add domain file instance tracking to a column of this model
    def domain_file_column(column_name)
      after_save "pre_process_domain_file_instance_#{column_name}"
      after_save "post_process_file_instance_#{column_name}"
      after_destroy "destroy_file_instances"

      define_method("pre_process_domain_file_instance_#{column_name}")  do
        file_instance_column_replace(column_name)
      end

       define_method("post_process_file_instance_#{column_name}")  do
        file_instance_update(column_name)
      end     
    end
    
    # Will process file instances with editor_url's in column_name
    # and turn them into actual file urls while keeping track
    # of the failes associated with this column
    #
    # For example:
    #
    #     process_file_instance :body, :body_html
    #
    # will render the column `body` auto-mago-matically on save into `body_html`
    # and put live urls into body_html
    def process_file_instance(column_name,rendered_column_name)
      before_save "pre_process_file_instance_#{column_name}"
      after_save "post_process_file_instance_#{column_name}"
      after_destroy "destroy_file_instances"
      
      define_method("pre_process_file_instance_#{column_name}")  do
        file_instance_replace(column_name,rendered_column_name)
      end      
      define_method("post_process_file_instance_#{column_name}")  do
        file_instance_update(column_name,rendered_column_name)
      end      
    end

    # Accepts a hash of the form :field_name => :rendered_field_name 
    # and will apply the filter options specified in options[:filter] to 
    # during the conversion process. Also processes any filter instances
    # 
    # If apply_content_filter is passed a block, it will call that block
    # if options[:filter] does not exist to return the filter details.
    # 
    # see ContentFilter#self.filter for avilable filter options (these
    # are the equivalent of the options hash with an extra :filter key
    # specifying the name of the filter)
    def apply_content_filter(fields,options={},&block)
      if options[:filter]
        if options[:filter].is_a?(Hash)
          filter_details = options[:filter]
        else
          filter_details = {  :filter => options[:filter]}
        end
      end

      fields.each do |fld,output_fld|
        before_save "pre_process_content_filter_#{fld}"
        after_save "post_process_content_filter_#{fld}"
        after_destroy "destroy_file_instances"
      
        define_method("pre_process_content_filter_#{fld}")  do
          file_instance_replace(fld,output_fld,filter_details || block.call(self))
        end
        
        define_method("post_process_content_filter_#{fld}")  do
          file_instance_update(fld,output_fld)
        end
      end
    end

    # Accepts a hash of the form :field_name => :rendered_field_name 
    # and will apply the filter options specified in options[:filter] to 
    # during the conversion process. Unline apply_content_filter, however
    # it will not execture file replacements
    # 
    # If safe_content_filter is passed a block, it will call that block
    # if options[:filter] does not exist to return the filter details.
    # 
    # see ContentFilter#self.filter for avilable filter options (these
    # are the equivalent of the options hash with an extra :filter key
    # specifying the name of the filter) 
    def safe_content_filter(fields,options={},&block)
      if options[:filter]
        if options[:filter].is_a?(Hash)
          filter_details = options[:filter]
        else
          filter_details = {  :filter => options[:filter]}
        end
      end

      fields.each do |fld,output_fld|
        before_save "pre_process_content_filter_#{fld}"
        define_method("pre_process_content_filter_#{fld}")  do
          content_filter_execute(fld,output_fld,filter_details || block.call(self))
        end
      end
    end
    
  end
  
  def self.append_features(mod) #:nodoc:
    super
    mod.extend ModelExtension::FileInstanceExtension::ClassMethods
  end
  
  def file_instance_search(column_name,html=nil) #:nodoc:
    file_ids = []
    html = self.send(column_name).to_s if html.blank?
    html.scan(/\/__fs__\/([0-9a-fA-F\/]+)(\:([a-zA-Z_\-]+)){0,1}/) do |prefix,slash,size|
      file_ids << prefix.split("/")[-1].to_i
    end
    files = DomainFile.find(:all,:conditions => { :id => file_ids })
    indexed_files = files.index_by(&:id)
    @file_instance_affected ||={}
    @file_instance_affected[column_name.to_s] = files.map(&:id).uniq

    indexed_files
  end

  def content_filter_execute(column_name,rendered_column_name,content_filter={}) #:nodoc:
    content_filter = content_filter.clone
    html = self.send(column_name).to_s
    if content_filter
      content_filter.symbolize_keys!
      if filter = content_filter.delete(:filter)
        html = ContentFilter.filter(filter,html,content_filter)
      end
    end
    self.send("#{rendered_column_name}=",html)
  end
  
  def file_instance_replace(column_name,rendered_column_name,content_filter={}) #:nodoc:
    html = self.send(column_name).to_s
    if content_filter
      content_filter.symbolize_keys!
      if filter = content_filter.delete(:filter)
        html = ContentFilter.filter(filter,html,content_filter)
      end
    end
    indexed_files = file_instance_search(column_name,html)
    html = html.gsub(/\/__fs__\/([0-9a-fA-F\/]+)(\:([a-zA-Z_\-]+)){0,1}/) do |match|
      size = $3 ? $3 : nil
      file_id = $1.split("/")[-1].to_i
      file = indexed_files[file_id.to_i]
      if file
       file.url(size)
      else
        "/images/missing_image.gif"
      end
    end
    self.send("#{rendered_column_name}=",html)
  end

  def file_instance_column_replace(column_name) #:nodoc:
    if self.send("#{column_name}_changed?")
      @file_instance_affected ||={}
      @file_instance_affected[column_name.to_s] = [ self.send(column_name) ]
    end
  end
  
  def file_instance_update(column_name,rendered_column_name=nil) #:nodoc:
    destroy_file_instances(column_name)
    value_str = ",'#{self.class.class_name}','#{self.id}','#{column_name}')"

    if  @file_instance_affected && @file_instance_affected[column_name.to_s] 
      @file_instance_affected[column_name.to_s].reject!(&:blank?)
      if @file_instance_affected[column_name.to_s].length > 0 
        DomainFileInstance.connection.execute("INSERT INTO domain_file_instances (`domain_file_id`,`target_type`,`target_id`,`column`) VALUES " + 
                                              @file_instance_affected[column_name.to_s].map { |fid| "(#{fid}" + value_str }.join(",") )
      end
    end
  end
  
  def destroy_file_instances(column_name=nil) #:nodoc:
    if(column_name)
      DomainFileInstance.delete_all({ :target_type => self.class.to_s, :target_id => self.id,:column => column_name.to_s })
    else
      DomainFileInstance.delete_all({ :target_type => self.class.to_s, :target_id => self.id })
    end
  end

end
