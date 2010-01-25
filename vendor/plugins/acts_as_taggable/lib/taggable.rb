require 'active_support'
require 'active_record'

module Taggable
  module Acts #:nodoc:
    module AsTaggable #:nodoc:
      
      def self.append_features(base) #:nodoc:
        super
        base.extend(ClassMethods)  
      end

      def self.split_tag_names(tags, separator,normalizer)
        tag_names = []
        if tags.is_a?(Array)
          tag_names << tags 
        elsif tags.is_a?(String)
          tag_names << (separator.is_a?(Proc) ? separator.call(tags) : tags.split(separator))
        end
        tag_names = tag_names.flatten.map { |name| normalizer.call(name.strip) }.uniq.compact #straight 'em up
      end

      # This mixin provides an easy way for adding tagging capabilities (also 
      # known as folksnomy) to your active record objects. It allows you to add
      # tags to your objects as well as search for tagged objects.
      # 
      # It assumes you are using a fully-normalized tagging database schema. For
      # that, you need a table (by default, named +tags+) to hold all tags in your 
      # application and this table must have a primary key (normally a +id+ int 
      # autonumber column) and a +name+ varchar column. You must also define a model class
      # related to this table (by default, named +Tag+).
      # 
      # All tag names will be stored in this tags table. Taggable objects should reside
      # in their own tables, like any other object.  Tagging objects is performed by 
      # the +acts_as_taggable+ mixin using a +has_and_belong_to_many+ relationship that is
      # automatically created on the taggable class, and as so, a join table must exist
      # between the tags table and the taggable object table.
      #
      # The name of the join table follows the standards for rails
      #
      # Unless the join table is explicitly specified as an option, 
      # it is guessed using the lexical order of the class names.
      #
      # The join table must be composed of the foreign keys from the tags table and the
      # taggable object table, so for instance, if we have a tags table named +tags+ (related
      # to a +Tag+ model) and a taggable +photos+ table (related to a +Photo+ model), 
      # there should be a join table +tags_photos+ with int FK columns +photo_id+ and +tag_id+. 
      # If you dont use a explicit full model related to the join table (through the 
      # +:join_class_name+ option), you must not add a primary key to the join table.
      #
      # The +acts_as_taggable+ adds the instance methods +tag+, +tag_names+, 
      # +tag_names= +, +tag_names<< +, +tagged_with? + for adding tags to the object 
      # and also the class method +find_tagged_with+ method for search tagged objects.
      #
      # Examples:
      # 
      #   class Photo < ActiveRecord::Base
      #     # this creates a 'tags' collection, through a has_and_belongs_to_many 
      #     # relationship that utilizes the join table 'photos_tags'.
      #     acts_as_taggable :normalizer => Proc.new {|name| name.downcase}
      #   end
      #
      #   photo = Photo.new
      #
      #   # splits and adds to the tags collection
      #   photo.tag "wine beer alcohol" 
      #
      #   # don't need to split since it's an array, but replaces the tags collection
      #   # trailing and leading spaces are properly removed
      #   photo.tag [ 'wine ', ' vodka'], :clear => true  
      #
      #   photo.tag_names # => [ 'wine', 'vodka' ]
      #   # You can remove tags one at a time or in a group
      #   photo.tag_remove 'wine'
      #   photo.tag_remove 'wine beer alcohol'
      #
      #   # appends new tags with a different separator
      #   # the 'wine' tag wont be duplicated
      #   photo.tag_names << 'wine, beer, alcohol', :separator => ','
      #
      #   # The difference between +tag_names+ and +tags+ is that +tag_names+ 
      #   # holds an array of String objects, mapped from +tags+, while +tags+ 
      #   # holds the actual +has_and_belongs_to_many+ collection, and so, is
      #   # composed of +Tag+ objects.
      #   photo.tag_names.size # => 4
      #   photo.tags.size # => 4
      #   # Now you can clear all tags in one call
      #   photo.clear_tags! 
      #
      #   # Find photos with 'wine' OR 'whisky'
      #   Photo.find_tagged_with :any => [ 'wine', 'whisky' ]
      #
      #   # Finds photos with 'wine' AND 'whisky' using a different separator.
      #   # This is also known as tag combos.
      #   Photo.find_tagged_with(:all => 'wine+whisky', :separator => '+'
      #
      #   # Gets the top 10 tags for all photos
      #   Photo.tags_count :limit => 10 # => { 'beer' => 68, 'wine' => 37, 'vodka' => '22', ... }
      #
      #   # Gets the tags count that are greater than 30
      #   Photo.tags_count :count => '> 30' # => { 'beer' => 68, 'wine' => 37 }
      #   
      #   # Replace allows you to find_tagged_with, remove the old tags and add the new ones
      #   Photo.replace_tag("beer whisky","wine vodka")
      #   # Display the photos returned from the tags_count call using 9 different CSS classes
      #   <% Photo.cloud(@photo_tags, %w(cloud1 cloud2 cloud3 cloud4 cloud5 cloud6 cloud7 cloud8 cloud9)) do |tag, cloud_class| %>
      #     <%= link_to(h("<#{tag}>"), tag_photos_url(:name => tag), { :class => cloud_class } ) -%>
      #   <% end %>
      #
      #   # Display the photos returned from the tags_count call using 5 different font sizes
      #   <% Photo.cloud(@photo_tags, %w(x-small small medium large x-large)) do |tag, font_size| %>
      #     <%= link_to(h("<#{tag}>"), tag_photos_url(:name => tag), { style: => "font-size: #{font_size}" } ) -%>
      #   <% end %>
      #
      # You can also use full join models if you want to take advantage of 
      # ActiveRecords callbacks, timestamping, inheritance and other features
      # on the join records as well. For that, you use the +:join_class_name+ option.
      # In this case, the join table must have a primary key.
      #
      #   class Person
      #     # This defines a class +TagPerson+ automagically.
      #     acts_as_taggable :join_class_name => 'TagPerson'
      #   end
      #
      #   # We can open the +TagPerson+ class and add features to it.
      #   class TagPerson
      #     acts_as_list :scope => :person
      #     belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
      #     before_save :do_some_validation
      #     after_save :do_some_stats
      #   end
      #
      #   # We can do some interesting things with it now
      #   person = Person.new
      #   person.tag "wine beer alcohol", :attributes => { :created_by_id => 1 }
      #   Person.find_tagged_with(:any => 'wine', :condition => "tags_people.created_by_id = 1 AND tags_people.position = 1")
      module ClassMethods
 
        # This method defines a +has_and_belongs_to_many+ relationship between
        # the target class and the tag model class. It also adds several instance methods
        # for tagging objects of the target class, as well as a class method for searching
        # objects that contains specific tags.
        # 
        # The options are:
        #
        # The +:collection+ parameter receives a symbol defining
        # the name of the tag collection method and it defaults to +:tags+.
        #
        # The +:tag_class_name+ parameter receives the tag model class name and
        # it defaults to +'Tag'+.
        #
        # The +:tag_class_column_name+ parameter receives the tag model class name attribute and
        # it defaults to +'name'+.
        #
        # The +:normalizer + paramater takes a Procs. This is used to normalize all tags
        # Simple example    
        # :normalizer => Proc.new {|name| name.capitalize}
        #
        # The +:join_class_name+ parameter receives the model class name that joins
        # the tag model and the taggable model. This automagically defines the join model
        # class that can be opened and extended.
        #
        # The remaining options are passed on to the +has_and_belongs_to_many+ declaration.
        # The +:join_table+ parameter is defined by default using the standard +has_and_belongs_to_many+ behavior.
        def acts_as_taggable(options = {})

          options = { :collection => :tags, :tag_class_name => 'Tag', :tag_class_column_name => 'name', :normalizer=> Proc.new {|name| name}}.merge(options)
          collection_name = options[:collection]
          tag_model = options[:tag_class_name].constantize
          tag_model_name = options[:tag_class_column_name]
          normalizer = options[:normalizer]
          if tag_model.table_name < self.table_name
            default_join_table = "#{tag_model.table_name}_#{self.table_name}"
          else
            default_join_table = "#{self.table_name}_#{tag_model.table_name}"
          end
          options[:join_table] ||= default_join_table
          options[:foreign_key] ||= self.name.to_s.foreign_key
          options[:association_foreign_key] ||= tag_model.to_s.foreign_key
         
          # not using a simple has_and_belongs_to_many but a full model
          # for joining the tags table and the taggable object table
          if join_class_name = options[:join_class_name]
            
            join_model = join_class_name.constantize
            tagged = self
            join_model.class_eval do
              belongs_to :tag, :class_name => tag_model.to_s
              belongs_to :tagged, :class_name => tagged.name.to_s
              define_method(:normalizer, normalizer) 
              define_method(tag_model_name.to_sym) { self[tag_model_name] ||= normalizer(tag.send(tag_model_name.to_sym)) }
            end
            
            
            options[:class_name] ||= join_model.to_s
            tag_pk, tag_fk = tag_model.primary_key, options[:association_foreign_key]
            t, tn, jt = tag_model.table_name, tag_model_name, join_model.table_name
            options[:finder_sql] ||= "SELECT #{jt}.*, #{t}.#{tn} AS #{tn} FROM #{jt}, #{t} WHERE #{jt}.#{tag_fk} = #{t}.#{tag_pk} AND #{jt}.#{options[:foreign_key]} = \#{quoted_id}"
          else
            join_model = nil
          end
          
          # set some class-wide attributes needed in class and instance methods                    
          write_inheritable_attribute(:tag_foreign_key, options[:association_foreign_key])                
          write_inheritable_attribute(:taggable_foreign_key, options[:foreign_key])                
          write_inheritable_attribute(:normalizer, normalizer)                
          write_inheritable_attribute(:tag_collection_name, collection_name)
          write_inheritable_attribute(:tag_model, tag_model)
          write_inheritable_attribute(:tag_model_name, tag_model_name)
          write_inheritable_attribute(:tags_join_model, join_model)
          write_inheritable_attribute(:tags_join_table, options[:join_table])                                      
          write_inheritable_attribute(:tag_options, options)
          
          [ :collection, :tag_class_name, :tag_class_column_name, :join_class_name,:normalizer].each { |key| options.delete(key) } # remove these, we don't need it anymore
          [ :join_table, :association_foreign_key ].each { |key| options.delete(key) } if join_model # dont need this for has_many

          # now, finally add the proper relationships          
          class_eval do
            include Taggable::Acts::AsTaggable::InstanceMethods
            extend Taggable::Acts::AsTaggable::SingletonMethods            
            
            class_inheritable_reader :tag_collection_name, :tag_model, :tag_model_name, :tags_join_model, 
                                     :tags_options, :tags_join_table,
                                     :tag_foreign_key, :taggable_foreign_key,:normalizer
            if join_model
              has_many collection_name, options
            else
              has_and_belongs_to_many collection_name, options
            end
          end                     
          
        end
      end
      
      module SingletonMethods
        # This method searches for objects of the taggable class and subclasses that
        # contains specific tags associated to them. The tags to be searched for can
        # be passed to the +:any+ or +:all+ options, either as a String or an Array. 
        #
        # The options are:
        #
        # +:any+: searches objects that are related to ANY of the given tags
        #
        # +:all+: searcher objects that are related to ALL of the given tags        
        #
        # +:separator+: a string, regex or Proc object that will be used to split the
        # tags string passed to +:any+ or +:all+ using a regular +String#split+ method.
        # If a Proc is passed, the proc should split the string in any way it wants 
        # and return an array of strings.
        #
        # +:conditions+: any additional conditions that should be appended to the 
        # WHERE clause of the finder SQL. Just like regular +ActiveRecord::Base#find+ methods.
        #
        # +:order+: the same as used in regular +ActiveRecord::Base#find+ methods.
        #
        # +:limit+: the same as used in regular +ActiveRecord::Base#find+ methods.
        def find_tagged_with(options = {}) 
          options = { :separator => ' ' }.merge(options)
          
          tag_names = Taggable::Acts::AsTaggable.split_tag_names(options[:any] || options[:all], options[:separator], normalizer)
          raise "No tags were passed to :any or :all options" if tag_names.empty?

          o, o_pk, o_fk, t, tn, t_pk, t_fk, jt = set_locals_for_sql
          sql = "SELECT #{o}.* FROM #{jt}, #{o}, #{t} WHERE #{jt}.#{t_fk} = #{t}.#{t_pk} 
                AND #{o}.#{o_pk} = #{jt}.#{o_fk}"
          sql << " AND  ("
          sql << tag_names.collect {|tag| sanitize_sql( ["#{t}.#{tn} = ?",tag])}.join(" OR ")
          sql << ")"
          sql << " AND #{sanitize_sql(options[:conditions])}" if options[:conditions]
          if postgresql?
            sql << " GROUP BY #{model_columns_for_sql}"
          else
            sql << " GROUP BY #{o}.#{o_pk}"
          end
          sql << " HAVING COUNT(#{o}.#{o_pk}) = #{tag_names.length}" if options[:all]              
          sql << " ORDER BY #{options[:order]} " if options[:order]
          add_limit!(sql, options)
          
          find_by_sql(sql)
        end
        #Looks for items with and old_tag and replaces it with all of new_tag
        # The +old_tag+ ,+new_tag+ parameters can be a +String+, +Array+ or a +Proc+ object. 
        # If it's a +String+, it's split using the +:separator+ specified in 
        # the +options+ hash. If it's an +Array+ it is flattened and compacted. 
        # Duplicate entries will be removed as well. Tag names are also stripped 
        # of trailing and leading whitespace. If a Proc is passed, 
        # the proc should split the string in any way it wants and return an array of strings.
        #
        # The +options+ hash has the following parameters:
        #
        # +:separator+: a string, regex or Proc object that will be used to split the
        # tags string passed to +:any+ or +:all+ using a regular +String#split+ method.
        # If a Proc is passed, the proc should split the string in any way it wants 
        # and return an array of strings.
        #
        # +:conditions+: any additional conditions that should be appended to the 
        # WHERE clause of the finder SQL. Just like regular +ActiveRecord::Base#find+ methods.
        #
        def replace_tag(old_tag,new_tag,options = {})

          options = { :any => old_tag ,:separator => ' ', :conditions => nil }.merge(options)
          find_tagged_with(options).each do |item|
            item.tag_remove(old_tag)
            item.tag(new_tag, :separator => options[:separator])
          end
        end
        
        # This method counts the number of times the tags have been applied to your objects
        # and, by default, returns a hash in the form of { 'tag_name' => count, ... }
        #
        # The options are:
        #
        # +:raw+: If you just want to get the raw output of the SQL statement (Array of Hashes), instead of the regular tags count Hash, set this to +true+.
        #
        # +:conditions+: any additional conditions that should be appended to the 
        # WHERE clause of the SQL. Just like in regular +ActiveRecord::Base#find+ methods.
        #        
        # +:order+: The same as used in +ActiveRecord::Base#find+ methods. By default, this is 'count DESC'. 
        # This should only be used if you want to modify the SQL  - to have sorted result be returned use +:sort_list+:
        #
        # +:sort_list+: This is a proc that is used to return a sorted list instead of a hash
        #        
        # +:count+: Adds a HAVING clause to the SQL statement, where you can set conditions for the 'count' column. For example: '> 50'
        #
        # +:limit+: the same as used in regular +ActiveRecord::Base#find+ methods.
        def tags_count(options = {})
          options = {:order => 'count DESC'}.merge(options)
          
          o, o_pk, o_fk, t, tn, t_pk, t_fk, jt = set_locals_for_sql
          sql = "SELECT #{t}.#{t_pk} AS id, #{t}.#{tn} AS name, COUNT(*) AS count FROM #{jt}, #{o}, #{t} WHERE #{jt}.#{t_fk} = #{t}.#{t_pk} 
                AND #{jt}.#{o_fk} = #{o}.#{o_pk}"
          sql << " AND #{sanitize_sql(options[:conditions])}" if options[:conditions]

          sql << " GROUP BY  #{t}.#{t_pk},#{t}.#{tn}"
          sql << " HAVING count #{options[:count]} " if options[:count]
          sql << " ORDER BY #{options[:order]} " if options[:order]
          add_limit!(sql, options)
          result = connection.select_all(sql)
          if !options[:raw]
            count = result.inject({}) { |hsh, row| hsh[row["#{tn}"]] = row['count'].to_i; hsh }
            if options[:sort_list] && options[:sort_list].is_a?(Proc)
                count = options[:sort_list].call(count.keys.collect{|key| [key,count[key]]})
            end
          end
                    
          count || result
        end
        #This method returns a simple count of the number of distinct objects 
        #Which match the tags provided
        # by Lon Baker
        def count_uniq_tagged_with(options = {}) 
            options = { :separator => ' ' }.merge(options)

            tag_names = Taggable::Acts::AsTaggable.split_tag_names(options[:any] || options[:all], options[:separator], normalizer)
            raise "No tags were passed to :any or :all options" if tag_names.empty?

            o, o_pk, o_fk, t, tn, t_pk, t_fk, jt = set_locals_for_sql
            sql = "SELECT COUNT(DISTINCT #{o}.#{o_pk}) FROM #{jt}, #{o}, #{t} WHERE #{jt}.#{t_fk} = #{t}.#{t_pk} 
                   AND #{o}.#{o_pk} = #{jt}.#{o_fk}"
          sql << " AND  ("
          sql << tag_names.collect {|tag| sanitize_sql( ["#{t}.#{tn} = ?",tag])}.join(" OR ")
          sql << ")"
          sql << " AND #{sanitize_sql(options[:conditions])}" if options[:conditions]
          sql << " HAVING COUNT(#{o}.#{o_pk}) = #{tag_names.length}" if options[:all]

            count_by_sql(sql)
        end
        
        # Alias for +tags_count+
        alias_method :tag_count, :tags_count

        # Finds other records that share the most tags with the record passed
        # as the +related+ parameter. Useful for constructing 'Related' or 
        # 'See Also' boxes and lists.
        #
        # The options are:
        # 
        # +:limit+: defaults to 5, which means the method will return the top 5 records
        # that share the greatest number of tags with the passed one.        
        # +:conditions+: any additional conditions that should be appended to the 
        # WHERE clause of the finder SQL. Just like regular +ActiveRecord::Base#find+ methods.
        def find_related_tagged(related, options = {})
          related_id = related.is_a?(self) ? related.id : related
          options = { :limit => 5 }.merge(options)
          
          o, o_pk, o_fk, t, tn, t_pk, t_fk, jt = set_locals_for_sql
          sql = "SELECT o.*, COUNT(jt2.#{o_fk}) AS count FROM #{o} o, #{jt} jt, #{t} t, #{jt} jt2 
                 WHERE jt.#{o_fk}=#{related_id} AND t.#{t_pk} = jt.#{t_fk} 
                 AND jt2.#{o_fk} != jt.#{o_fk} 
                 AND jt2.#{t_fk}=jt.#{t_fk} AND o.#{o_pk} = jt2.#{o_fk}"
          sql << " AND #{sanitize_sql(options[:conditions])}" if options[:conditions]
          sql << " GROUP BY o.#{o_pk}"
          sql << " ORDER BY count DESC"
          add_limit!(sql, options)
          
          find_by_sql(sql)          
        end

        # Finds other tags that are related to the tags passed through the +tags+
        # parameter, by finding common records that share similar sets of tags.
        # Useful for constructing 'Related tags' lists.
        #
        # The options are:
        #
        # +:separator+ => defines the separator (String or Regex) used to split 
        # the tags parameter and defaults to ' ' (space and line breaks).
        #
        # +:raw+: If you just want to get the raw output of the SQL statement (Array of Hashes), instead of the regular tags count Hash, set this to +true+.
        #
        # +:limit+: the same as used in regular +ActiveRecord::Base#find+ methods.
        def find_related_tags(tags, options = {})                
          tag_names = Taggable::Acts::AsTaggable.split_tag_names(tags, options[:separator], normalizer)
          o, o_pk, o_fk, t, tn, t_pk, t_fk, jt = set_locals_for_sql
          options[:limit] += 1 if options[:limit]  # Compensates for the counting of the original argument

          
          sql = "SELECT jt.#{o_fk} AS o_id FROM #{jt} jt, #{t} t 
                 WHERE jt.#{t_fk} = t.#{t_pk} "
          sql << " AND  ( t.#{tn} IN ("
          sql << quote_bound_value(tag_names)
          sql << "))"
          sql << "GROUP BY jt.#{o_fk} 
                 HAVING COUNT(jt.#{o_fk})=#{tag_names.length}"
          
          o_ids = connection.select_all(sql).map { |row| row['o_id'] }
          return options[:raw] ? [] : {} if o_ids.length < 1

          sql = "SELECT t.#{t_pk} AS id, t.#{tn} AS #{tn}, COUNT(jt.#{o_fk}) AS count FROM #{jt} jt, #{t} t 
                 WHERE jt.#{o_fk} IN (#{o_ids.join(",")}) 
                 AND t.#{t_pk} = jt.#{t_fk}
                 GROUP BY t.#{t_pk},t.#{tn},jt.#{t_fk} 
                 ORDER BY count DESC"
          add_limit!(sql, options)
          
          result = connection.select_all(sql).delete_if { |row| tag_names.include?(row["#{tn}"]) }
          count = result.inject({}) { |hsh, row| hsh[row["#{tn}"]] = row['count'].to_i; hsh } unless options[:raw]
                    
          count || result
        end
        
        # Takes the result of a tags_count call and an array of categories and 
        # distributes the entries in the tags_count hash evenly across the
        # categories based on the count value for each tag.
        #
        # Typically, this is used to display a 'tag cloud' in your UI.
        #
        # The options are:
        #
        # +tag_hash+ => The tag hash returned from a tags_count call
        #
        # +category_list+ => An array containing the categories to split the tags
        # into
        #
        # +block+ => { |tag, category| }
        # 
        # The block parameters are:
        #
        # +:tag+ => The tag key from the tag_hash
        #
        # +:category+ => The category value from the category_list that this tag 
        # is in
        def cloud(tag_hash, category_list)
          max, min = 0, 0
          tag_hash.each_value do |count|
            max = count if count > max
            min = count if count < min
          end
      
          divisor = ((max - min) / category_list.size) + 1
          
          tag_hash.each do |tag, count|
            yield tag, category_list[(count - min) / divisor] 
          end
        end
        
        private
        def postgresql?
          ActiveRecord::Base.connection.adapter_name == "PostgreSQL" ? true : false
        end
        def mysql?
          ActiveRecord::Base.connection.adapter_name == "MySQL" ? true : false
        end
        def model_columns_for_sql
            self.column_names.collect {|c| c = "#{table_name}.#{c}"}.join(',')
        end
        def tag_model_columns_for_sql
            tag_model.column_names.collect {|c| c = "#{tag_model.table_name}.#{c}"}.join(',')
        end
        def set_locals_for_sql
          [ table_name, primary_key, taggable_foreign_key,
            tag_model.table_name, tag_model_name, tag_model.primary_key, tag_foreign_key,
            tags_join_model ? tags_join_model.table_name : tags_join_table ]
        end
        
      end
      
      module InstanceMethods
        # Handles clearing all associated tags
        def clear_tags!
            if tags_join_model
                tag_collection.each {|x| x.destroy}
            else
                tag_collection.clear
            end
        end
        # This method removes tags from the target object, by parsing the tags parameter
        # into Tag object instances and removing them from the tag collection of the object if they exist.
        #
        # The +tags+ parameter can be a +String+, +Array+ or a +Proc+ object. 
        # If it's a +String+, it's split using the +:separator+ specified in 
        # the +options+ hash. If it's an +Array+ it is flattened and compacted. 
        # Duplicate entries will be removed as well. Tag names are also stripped 
        # of trailing and leading whitespace. If a Proc is passed, 
        # the proc should split the string in any way it wants and return an array of strings.
        #
        # The +options+ hash has the following parameters:
        #
        # +:separator+ => defines the separator (String or Regex) used to split 
        # the tags parameter and defaults to ' ' (space and line breaks).
        def tag_remove(tags, options = {})
      
          options = { :separator => ' '}.merge(options)
          attributes = options[:attributes] || {}     
          
          # parse the tags parameter
          tag_names = Taggable::Acts::AsTaggable.split_tag_names(tags, options[:separator], normalizer)
          
          # remove the tag names to the collection
          tag_names.each do |name| 
            tg = Tag.find_by_name(name)
            EndUserTag.delete_all({  :end_user_id => self.id, :tag_id => tg.id }) if tg
          end
        end

        # This method applies tags to the target object, by parsing the tags parameter
        # into Tag object instances and adding them to the tag collection of the object.
        # If the tag name already exists in the tags table, it just adds a relationship
        # to the existing tag record. If it doesn't exist, it then creates a new
        # Tag record for it. 
        #
        # The +tags+ parameter can be a +String+, +Array+ or a +Proc+ object. 
        # If it's a +String+, it's split using the +:separator+ specified in 
        # the +options+ hash. If it's an +Array+ it is flattened and compacted. 
        # Duplicate entries will be removed as well. Tag names are also stripped 
        # of trailing and leading whitespace. If a Proc is passed, 
        # the proc should split the string in any way it wants and return an array of strings.
        #
        # The +options+ hash has the following parameters:
        #
        # +:separator+ => defines the separator (String or Regex) used to split 
        # the tags parameter and defaults to ' ' (space and line breaks).
        #
        # +:clear+ => defines whether the existing tag collection will be cleared before
        # applying the new +tags+ passed. Defaults to +false+.
        def tag(tags, options = {})
      
          options = { :separator => ' ', :clear => false }.merge(options)
          attributes = options[:attributes] || {}     
          
          # parse the tags parameter
          tag_names = Taggable::Acts::AsTaggable.split_tag_names(tags, options[:separator], normalizer)
          
          # clear the collection if appropriate
          self.clear_tags! if options[:clear]
      
          # append the tag names to the collection
          tag_names.each do |name| 
            # ensure that tag names don't get duplicated           
            tag_record = tag_model.find(:first, :conditions=>["#{tag_model_name} = ?",name]) || tag_model.new(tag_model_name.to_sym => name)
            if tags_join_model
              tag_join_record = tags_join_model.new(attributes)
              tag_join_record.tag = tag_record
              tag_join_record.tagged = self
              tag_collection << tag_join_record unless tagged_with?(name)
            else
              tag_collection << tag_record unless tagged_with?(name)
            end
          end
          
        end

        # Clears the current tags collection and sets the tag names for this object.
        # Equivalent of calling #tag(..., :clear => true)        
        #
        # Another way of appending tags to a existing tags collection is by using
        # the +<<+ or +concat+ method on +tag_names+, which is equivalent of calling
        # #tag(..., :clear => false).
        def tag_names=(tags, options = {})
          tag(tags, options.merge(:clear => true))
        end
      
        # Returns an array of strings containing the tags applied to this object.
        # If +reload+ is +true+, the tags collection is reloaded.
        def tag_names(reload = false)
          ary = tag_collection(reload).map { |tag| tag.send(tag_model_name.to_sym)}
          ary.extend(TagNamesMixin)
          ary.set_tag_container(self)
          ary
        end
        
        # Checks to see if this object has been tagged with +tag_name+.
        # If +reload+ is true, reloads the tag collection before doing the check.
        def tagged_with?(tag_name, reload = false)
          tag_names(reload).include?(tag_name)
        end
        # Checks to see if this object has been tagged with all +tags+ - they can be a string,or list
        # The +options+ hash has the following parameters:
        # +:separator+ => defines the separator (String or Regex) used to split 
        # the tags parameter and defaults to ' ' (space and line breaks).
        # +:reload+ => That forces the tag names to be reloaded first
        def tagged_with_all?(tags, options = {})
            options = { :separator => ' ', :reload => false }.merge(options)
            requested= Taggable::Acts::AsTaggable.split_tag_names(tags, options[:separator], normalizer)
            tag_names(options[:reload]) if options[:reload]
            requested.each {|tag_name| 
                return false if !tag_names.include?(tag_name)
            }
            return true
        end
        # Checks to see if this object has been tagged with any +tags+ - they can be a string,or list
        # The +options+ hash has the following parameters:
        # +:separator+ => defines the separator (String or Regex) used to split 
        # the tags parameter and defaults to ' ' (space and line breaks).
        # +:reload+ => That forces the tag names to be reloaded first
        def tagged_with_any?(tags, options = {})
            options = { :separator => ' ', :reload => false }.merge(options)
            requested= Taggable::Acts::AsTaggable.split_tag_names(tags, options[:separator], normalizer)
            tag_names(options[:reload]) if options[:reload]
            requested.each {|tag_name| 
                return true if tag_names.include?(tag_name)
            }
            return false
        end

        # Calls +find_related_tagged+ passing +self+ as the +related+ parameter.
        def tagged_related(options = {})
          self.class.find_related_tagged(self.id, options)
        end
        
        private
        def tag_model
          self.class.tag_model
        end
        
        def tag_collection(reload = false)
          send(self.class.tag_collection_name, reload) 
        end        

        def tags_join_model
          self.class.tags_join_model
        end
                
      end
            
      module TagNamesMixin #:nodoc:
      
        def set_tag_container(tag_container)
          @tag_container = tag_container
        end
        
        def <<(tags, options = {})
          @tag_container.tag(tags, options.merge(:clear => false))            
        end
        
        alias_method :concat, :<<
      end
        
    end
  end
end

