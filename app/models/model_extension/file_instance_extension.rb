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

    def apply_content_filter(fields,options={},&block)
      filter_name = options[:filter]

      fields.each do |fld,output_fld|
        before_save "pre_process_content_filter_#{fld}"
        after_save "post_process_content_filter_#{fld}"
        after_destroy "destroy_file_instances"
      
        define_method("pre_process_content_filter_#{fld}")  do
          file_instance_replace(fld,output_fld,filter_name || block.call(self))
        end
        
        define_method("post_process_content_filter_#{fld}")  do
          file_instance_update(fld,output_fld)
        end
      end
    end
    
  end
  
  def self.append_features(mod)
    super
    mod.extend ModelExtension::FileInstanceExtension::ClassMethods
  end
  
  def file_instance_search(column_name)
    file_ids = []
    self.send(column_name).to_s.scan(/\/__fs__\/([0-9a-fA-F\/]+)(\:([a-zA-Z_]+)){0,1}/) do |prefix,slash,size|
      file_ids << prefix.split("/")[-1].to_i
    end
    files = DomainFile.find(:all,:conditions => { :id => file_ids })
    indexed_files = files.index_by(&:id)
    @file_instance_affected ||={}
    @file_instance_affected[column_name.to_s] = files.map(&:id).uniq

    indexed_files

    
  end
  
  def file_instance_replace(column_name,rendered_column_name,content_filter=nil)
    indexed_files = file_instance_search(column_name)
    html = self.send(column_name).to_s
    if content_filter
      html = ContentFilter.filter(content_filter,html)
    end
    html = html.gsub(/\/__fs__\/([0-9a-fA-F\/]+)(\:([a-zA-Z_]+)){0,1}/) do |match|
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
  
  
  def file_instance_update(column_name,rendered_column_name=nil)
    destroy_file_instances(column_name)
    value_str = ",'#{self.class.to_s}','#{self.id}','#{column_name}')"


    if @file_instance_affected[column_name.to_s] && @file_instance_affected[column_name.to_s].length > 0 
      DomainFileInstance.connection.execute("INSERT INTO domain_file_instances (`domain_file_id`,`target_type`,`target_id`,`column`) VALUES " + 
        @file_instance_affected[column_name.to_s].map { |fid| "(#{fid}" + value_str }.join(",") )
    end
  end
  
  def destroy_file_instances(column_name=nil)
    if(column_name)
      DomainFileInstance.delete_all({ :target_type => self.class.to_s, :target_id => self.id,:column => column_name.to_s })
    else
      DomainFileInstance.delete_all({ :target_type => self.class.to_s, :target_id => self.id })
    end
  end

end
