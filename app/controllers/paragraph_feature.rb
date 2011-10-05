# Copyright (C) 2009 Pascal Rettig.

require 'radius'

=begin rdoc
ParagraphFeatures's are used to render paragraph output
in a highly user-customizable way

They are the view part of the trinty of classes used for 
configuring and rendering paragraphs (ParagraphController and ParagraphRenderer
are the other two).

ParagraphFeature's generally define a number of features using the ParagraphFeature#feature class method
and then define a method called [feature_name]_feature(data) that actually renders the feature.

=== Example

For example, a (abbreviated) feature for the poll demo might look like:

    class PollDemo::PageFeature < ParagraphFeature
       feature :poll_demo_page_view, :default_feature => <<-FEATURE
                  <cms:poll>
                     <cms:responded><cms:graph/></cms:responded>
                     <cms:form>
                       <b><cms:question/></b><br/>
                       <cms:response/><br/><cms:submit/>
                     </cms:form>
                  </cms:poll>
                  <cms:no_poll>Invalid Poll</cms:no_poll>
                FEATURE
       
       
       def poll_demo_page_view_feature(data)
             webiva_feature(:poll_demo_page_view,data) do |c|
               c.expansion_tag('poll') {  |t| data[:poll] }
               c.expansion_tag('responded') {  |t| data[:state] == 'responded'}
                  c.value_tag('responded:graph') do |t| 
                     data[:poll].results_graph(data[:options].graph_width,
                                           data[:options].graph_height)
                  end
              
               c.form_for_tag('form','poll') do |t|
                 if data[:state] == 'question'
                   { 
                     :object => data[:response],
                     :code => hidden_field_tag('poll[poll_demo_poll_id]',data[:poll].id)
                   }
                 end
               end
               c.h_tag('question') {  |t| data[:poll].question }
               c.field_tag('form:response',
                 :control => :radio_buttons, 
                 :separator => '<br/>') { |t| data[:poll].answer_options }
               c.submit_tag('form:submit',:default => 'Submit')
             end
           end
       
       ...
    end  


=== Naming Convention

A couple of things to note, first the feature names aren't namespaced, so you need to 
manually name space them. The standard method is [module_name]_[renderer_name]_[paragraph_name]
In the case about the module's name is "poll_demo", the renderer name is "page" and the paragraph
name is "view", so the feature is called :poll_demo_page_view.

== webiva_feature and webiva_custom_feature

Inside of the actual feature method is usually a call to webiva_feature or webiva_custom_feature,
which yields a context, inside of which you can define tags for the feature to use. The end
result of the webiva_feature (or webiva_custom_feature) call is the html that the feature renders,
using either the default feature or the customized feature defined by the site integrator.

When should you use which? Well, if you the tags that you define don't depend on the data variable
being passed in, then you can use webiva_feature. If they do depend on the data (for example in a custom 
content model publication you'll have different tags depending on the content mode) You should
use webiva_custom_feature so the system knows not to cache the generated tags.

Note: the caching is planned for the future, so using the correct call is only important for
future proofing your module

=== Defining Tags: Basic Radius

The "c" that webiva_feature passes to the block is called a FeatureContext. You can use it to define
tags that will be available in the feature. Webiva uses the excellent (Radius Gem)[http://github.com/jlong/radius]
to render features and the webiva class ParagraphFeature::FeatureContext inherits from Radius::Context. 

At the most basic level you can define tags using 'define_tag' - which is the standard radius method.

For example to create a tag that will be available as "<cms:name/>" in your ParagraphFeature you could write:

      c.define_tag('name') { |t| h(data[:object].name) }

If you wanted to be able to write something like: "<cms:object>We have an object!</cms:object>" that only
displays the text "We have an object!" you could define a tag like:

     c.define_tag('object') { |t| data[:object] ? t.expand : nil }

Radius also supports some local variables and nested tags. For example the above two tags could be written 
like:

     c.define_tag('object') do |t|
        t.locals.object = data[:object]
        t.locals.object ? t.expand : nil
     end
     c.define_tag('object:name') { |t| h(t.locals.object.name) }

This would allow a site feature like "<cms:object>Name: <cms:name/></cms:object>" which would only
display: "Name: .." if the object existed, and only allow the use of the <cms:name/> tag inside of
a <cms:object/> tag.

=== FeatureContext Tags

Writing define_tag and a whole bunch of display logic gets old quickly, so FeatureContext adds
a whole slew of tags that you can use in lieu of define_tag that add one or more tag with
specific functionality. The above could also be written:

    c.expansion_tag('object') { |t| t.locals.object = data[:object] }
    c.h_tag('object:name') { |t| t.locals.object.name }
        
See ParagraphFeature::FeatureContext for more information.

=== Usings features

Features are made available in ParagraphRenderer's by calling the 'feature /module/feature' class 
method and then either calling the feature directly via it's method name or by calling:

        render_paragraph :feature => :feature_name                                        

See ParagraphRenderer for more information.

=end
class ParagraphFeature

  # Include some helpers needed for
  # rendering pages
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::FormHelper
  include ERB::Util
  include EscapeHelper
  include ActionView::Helpers::FormTagHelper


  attr_reader :renderer
  

  def initialize(paragraph,renderer) #:nodoc:
    @para = paragraph
    @renderer = renderer
  end

  def method_missing(method,*args) #:nodoc:
    if method.to_s =~ /feature$/
      raise 'Undefined feature:' + method.to_s
    else
      if args.length > 0
        @renderer.send(method,*args)
      else
        @renderer.send(method)
      end
    end
  end

  # Creates a new standalone feature that can be called with a 
  # data hash directly. 
  def self.standalone_feature(site_feature_id=nil)
    self.new(PageParagraph.new(:site_feature_id => site_feature_id),dummy_renderer)
  end

  # Parses an inline feature
  def parse_inline(src,&block)
    parser_context = FeatureContext.new(self) do |c| 
      c.define_position_tags  
      yield c
     end 
     parse_feature(SiteFeature.new(:body => src),parser_context)
  end
  
  def self.dummy_renderer(controller=nil) #:nodoc:
    ParagraphRenderer.new(UserClass.domain_user_class,controller || ApplicationController.new,PageParagraph.new,SiteNode.new,PageRevision.new)
  end

  # Returns a list of tags that are defined in this feature
  def self.document_feature(name,data={},controller=nil,publication=nil)
    rnd = self.dummy_renderer(controller)
    feature = self.new(PageParagraph.new,rnd)
    feature.set_documentation(true)
    feature.send(name,data)
  end
  
  # Registers a feature named type.
  # Should be called with :default_feature option to show the markup for 
  # the default feature (otherwise by nothing will render)
  def self.feature(type,opts = {})
    features = self.available_features
    features << type
    
    sing = class << self; self; end
    sing.send :define_method, :available_features do 
      return features
    end 
    default_feature = opts.delete(:default_feature) || '' 
    sing.send :define_method, "get_default_feature_#{type.to_s}" do
      default_feature
    end
    sing.send :define_method, "get_feature_options_#{type.to_s}" do
      opts
    end
  end
  
  
=begin rdoc
FeatureContext is the context passed to site features when they call ParagraphFeathre#webiva_feature.
It includes most of the basic view helpers, allow you to call standard rails methods like
"tag" to generate an html tag. 

It also defines a number of custom tags methods for Webiva. All custom tag
methods are aliased without the leading "define", so define_expansion_tag is
also available as expansion_tag.

Most of the Webiva custom tags accept a block that returns the object on which the tag should 
act. For example - expansion_tag accepts a block and will only expand the tag if the value of
block is non-nil

=end  
  class FeatureContext < Radius::Context 
    include ActionView::Helpers::TagHelper
    include EscapeMethods
    include ActionView::Helpers::FormTagHelper
    include ActionView::Helpers::FormHelper
    include StyledFormBuilderGenerator::FormFor
    include ActionView::Helpers::FormOptionsHelper
    include PageHelper
    include EscapeHelper
    
    
    def url_for(opts) #:nodoc:
      if opts.nil?
	nil
      elsif opts.is_a? String
	opts
      else
	super opts
      end
    end
    
    def initialize(renderer=nil) #:nodoc:
      @renderer = renderer
      super()
    end
    
  def method_missing(method,*args) #:nodoc:
    if args.length > 0
      @renderer.send(method,*args)
    else
      @renderer.send(method)
    end 
  end
    
  # Defines a set of tags of the form [name]:[tag_name] for each
  # element of the array tag_names making it easy to expose a number
  # of attributes in an object. For example if we had an object in
  # t.locals.person with a first_name,last_name, and email attribute
  # we could write:
  #
  #     c.expansion_tag("person") { |t| t.locals.person = data[:person] }
  #     c.attribute_tags("person",["first_name","last_name","email"]) { |t| t.locals.person }
  #
  # which would add three tags:
  #
  #     <cms:person:first_name/>, <cms:person:last_name/>, <cms:person:email_name/>
  #
  def define_attribute_tags(name,tag_names,&block) 
    tag_names.each do |tag_name|
      define_attribute_tag_helper("#{name}:#{tag_name}",tag_name,block)
    end
  end
        
        def define_attribute_tag_helper(name,tag_name,block) #:nodoc:
          define_value_tag(name) do |t|
              h(block.call(t).send(tag_name))
          end
        end
    
    # Define a value tag and escape the output with a h call
    #
    # === Options
    # [:format]
    #   Set to :simple to call Rail's simple_format method around the returned, escaped value
    def define_h_tag(name,field='value',options={},&block)
      case options[:format]
      when :simple
        define_value_tag(name,field,&Proc.new { |t| val = block.call(t); val ? simple_format(h(val)) : nil })
      else
        define_value_tag(name,field,&Proc.new { |t| val = block.call(t); val ? h(val) : nil })
      end
    end

    def value_tag_helper(t,field,val) #:nodoc:
      t.locals.send("#{field}=",val)
      if t.attr['equals']
        eql = val.is_a?(Integer) ? t.attr['equals'].to_i : t.attr['equals']
        val == eql ? t.expand : nil
      elsif t.attr['contains']
        contains = t.attr['contains'].to_s.split(",").map { |elm| elm.strip.blank? ? nil : elm.strip }.compact
        contains.include?(val) ? t.expand : nil
      elsif t.attr['include']
        inc = val.is_a?(Array) && val.include?(t.attr['include'])
        inc ? t.expand : nil
      elsif t.attr['not_equals']
        eql = val.is_a?(Integer) ? t.attr['not_equals'].to_i : t.attr['not_equals']
        val != eql ? t.expand : nil
      elsif t.attr['min']
        min = val.is_a?(Integer) ? t.attr['min'].to_i : t.attr['min']
        val >= min ? t.expand : nil
      elsif t.attr['max']
        max = val.is_a?(Integer) ? t.attr['max'].to_i : t.attr['max']
        val <= max ? t.expand : nil
      elsif t.attr['link']
        attributes = t.attr.clone
        attributes.delete('link')
        content_tag('a',t.expand, attributes.merge({ :href => val}))
      else
        if val.is_a?(Array)
          val.length == 0 || val[0].blank? ? nil : t.expand
        else
          val.blank? ? nil : t.expand
        end
      end
    end

    def escape_value_helper(value,escape) #:nodoc:
      case escape
      when 'value':
        vh(value)
      when 'javascript':
        jh(value)
      when 'javascript_value':
        jvh(value)
      else
        h(value)
      end
    end
    
    # Defines a value tag, which is the standard tag that 
    # is used to output a piece of content. Using value_tag
    # instead of just define_tag allows for some additional functionality
    # including using the value tag as a block.
    # 
    # For example, if you defined a value tag called 'name' you could write:
    #
    #     <cms:name>Name: <cms:value/></cms:name>
    #
    # Which would only display the Name: .. text if the return value of the block
    # isn't blank.
    #
    # You can pass an "escape" attribute set to html, value, javascript or javascript_value
    # to escape the output of a tag as necessary
    #
    # You can also use the value as an expansion tag by passing any of the following:
    #  max="MAX VALUE", min="MIN_VALUE", not_equals="COMPARE VALUE",
    #  equals="COMPARE VALUE", contains="Multiple,Comma,Separated,Values"
    #
    #  For example:
    #
    #       <cms:age min='21'>Alcohol Reference</cms:age>
    #
    #  Which would only expand if the value of age is greater than 21
    #  
    def define_value_tag(name,field='value',&block)
      define_tag(name) do |tag|
        val = yield(tag)
        if tag.single?
          val = truncate(Util::TextFormatter.text_plain_generator(val), :length => tag.attr['limit'].to_i, :omission => tag.attr['omission'] || '...') if tag.attr['limit']
          if tag.attr['escape']
            escape_value_helper(val,tag.attr['escape']) 
          else 
            val
          end
        else
          value_tag_helper(tag,field,val)
        end
      end
      
      name_parts = name.split(":")
      name_parts[-1] = "no_" + name_parts[-1]
      
      define_tag(name_parts.join(":")) do |tag|
        val = block.call(tag)
        val.blank? ? tag.expand : nil
      end
      define_tag(name + ":#{field}") do |tag|
        tag.locals.send(field)
      end
    end
    
    # Loop tags are used to loop over a list of items, assign each item to a local
    # and then expand the interior of the tag.
    # For example lets say you had a list of "posts" in data[:posts] that you wanted
    # to iterate over, you could define a loop tag and a couple of attribute tags:
    #
    #       c.loop_tag('post') { |t| data[:posts] }
    #       c.attribute_tags('post',%w(name body)) { |t| t.locals.post }
    #
    # This would create a number of tags:
    # 
    # [<cms:posts>]
    #   Block tag that is expanded only if data[:posts] is non-nil and has a length > 0
    # [<cms:no_posts> or <cms:not_posts>]
    #   Block tags that are expanded only if data[:posts] is nil or has a length == 0
    # [<cms:post>]
    #   Block tag that is called once for each element of data[:posts], it will assign a local
    #   variable called t.locals.post that will contain the individual post
    # [<cms:post:name/>]
    #   h tag that will display the name for each post
    # [<cms:post:body/>]
    #   h that will display the body of each post
    # 
    # An example code usage would be:
    #
    #      <cms:posts>
    #      <div class='posts'>
    #        <cms:post>
    #        <div class='post'>     
    #          <h2><cms:name/></h2>
    #          <cms:body/>
    #        </div>
    #        </cms:post>
    #      </div>
    #      </cms:posts>
    #      <cms:no_posts><h2>No Posts</h2></cms:no_posts>
    def define_loop_tag(name,plural=nil,options = {})
      name_parts = name.split(":")
      name_base = options[:local] || name_parts[-1]
      plural = name_base.pluralize unless plural
      name_parts[-1] = plural
      
      expansion_tag = name_parts.join(":")
      define_tag(name) { |t| each_local_value(yield(t),t,name_base) }
      define_expansion_tag(expansion_tag) { |t| arr = yield(t); arr && arr.length > 0 }
    end
    
    # Expansion tags are block tags that will expand the value of the tag
    # if the block returns a non-nil value
    # a common usage is to assign a local in the yielded block
    #
    # For example:
    #
    #      c.expansion_tag('item') { |t| t.locals.item = data[:item] } 
    #      ..Now defines some tags underneath item:, like item:name, item:price, etc...
    # 
    def define_expansion_tag(name) 
      define_tag(name) do |tag|
        yield(tag) ? tag.expand : nil
      end
      name_parts = name.split(":")
      tg_name = name_parts[-1]
      name_parts[-1] = "no_" + tg_name
      
      define_tag(name_parts.join(":")) do |tag|
        yield(tag) ? nil : tag.expand
      end
      name_parts[-1] = "not_" + tg_name
      define_tag(name_parts.join(":")) do |tag|
        yield(tag) ? nil : tag.expand
      end

    end
    
    # Creates a tag that expects a date or time object to be returned by the yielded block.
    #
    # For example:
    #
    #     c.date_tag('current_time') { |t| Time.now }
    #
    def define_date_tag(name,default_format = nil,&block)
      define_value_tag(name) do |tag|
        val = yield(tag)
        if !val.is_a?(Time)
          begin 
            val = Time.parse(val)
          rescue Exception => e
            #
          end
        end
        val.localize(tag.attr['format'] || default_format || Configuration.date_format) if val
      end
    end

    # Creates a tag that expects a date or time object to be returned by the yielded block.
    #
    # For example:
    #
    #     c.datetime_tag('current_time') { |t| Time.now }
    #
    def define_datetime_tag(name,default_format = nil,&block)
      define_value_tag(name) do |tag|
        val = yield(tag)
        if !val.is_a?(Time)
          begin 
            val = Time.parse(val)
          rescue Exception => e
            #
          end
        end
        val.localize(tag.attr['format'] || default_format || Configuration.datetime_format) if val
      end
    end



    def reset_output #:nodoc:
      @output_buffer = ""
    end
    
    def concat(txt,binding=nil) #:nodoc:
      @output_buffer += txt
    end
    
    attr_reader :output_buffer

    # Creates an end user table, see EndUserTable for more information
    # (EndUserTable's are the equivalent of ActiveTable but for the front end
    # of the site)
    def define_end_user_table_tag(tag_name,field,options = {},&block) 
      options.symbolize_keys!
      define_tag(tag_name) do |t|
        
        opts = options.clone.merge(t.attr.symbolize_keys.slice(:empty,:style,:width))
        opts[:empty] ||= "No Entries"
        
        t.locals.tbl = yield t
        reset_output
        end_user_table_for(t.locals.tbl,opts) do |row|
          t.locals.send("#{field}=",row)
          concat(t.expand)
        end
        output_buffer
      end
      define_tag("#{tag_name}:row") do |t|  
        "<tr #{t.locals.tbl.highlight_row(t.locals.send(field))}>" + t.expand + "</tr>"
      end      
      
      define_tag("#{tag_name}:row:checkbox") do |t|
        t.locals.tbl.entry_checkbox(t.locals.send(field))
      end
    end
    
    # Helper method that defines a number of tags that provide information
    # about the current user.
    #
    #     user_tags('user') { |t| t.locals.user }
    #
    # Would define the following tags:
    # [<cms:user>]
    #   Expansion tag that only expands if the yield block returns non-nil
    # [<cms:user:logged_in>]
    #   Expansion tag that only expands if the user is logged in
    # [<cms:user:name/>]
    #   h tag that returns the full name of the user
    # [<cms:user:first_name/>]
    #   h tag the returns the users first name
    # [<cms:user:last_name/>]
    #   h tag the returns the users last name
    # [<cms:user:profile/>]
    #   value tag the returns the user's profile id
    # [<cms:user:myself>]
    #   expansion tag that expands only if the user is the currently logged in user
    def define_user_tags(tag_name,options={},&block)
      local=options[:local]
      if !local
        name_parts = tag_name.split(":")
        local = name_parts[-1]
      end

      define_expansion_tag(tag_name) { |t| block ? t.locals.send("#{local}=",block.call(t)) : t.locals.send(local) }
      define_expansion_tag(tag_name + ":logged_in") { |t| usr = t.locals.send(local); !usr.id.blank? }
      define_h_tag(tag_name + ":email") { |t| usr = t.locals.send(local); usr.email if usr }
      define_h_tag(tag_name + ":name") { |t| usr = t.locals.send(local); usr.name if usr }
      define_h_tag(tag_name + ":username") { |t| usr = t.locals.send(local); usr.username if usr }
      define_h_tag(tag_name + ":first_name") { |t| usr = t.locals.send(local); usr.first_name if usr }
      define_h_tag(tag_name + ":last_name") { |t| usr = t.locals.send(local); usr.last_name if usr }
      define_value_tag(tag_name + ":profile") { |t| usr = t.locals.send(local); usr.user_profile_id if usr }
      define_value_tag(tag_name + ":profile_name") { |t| usr = t.locals.send(local); usr.user_profile.name if usr }
      define_expansion_tag(tag_name + ":myself") { |t| usr = t.locals.send(local); usr == myself if usr }
      define_image_tag(tag_name + ":img") { |t| usr = t.locals.send(local); usr.image if usr }
    end

    # Similar to define_user_tags but it defines a whole bunch of tags
    # with detailed information about the user.
    #
    # the only option that is currently accepted is :local, which is the name
    # of the local variable to find the user object (defaults to the name of the tag)
    #
    #     expansion_tag('user') { |t| t.locals.user = data[:user] }
    #     user_details_tags('user', :local => 'user')
    #
    # Would define expansion tags for: myself,male,female,address,work_address
    # and would define value tag for:
    # user_id,first_name,last_name,salutation,name,email,cell_phone,img,second_img,fallback_img
    # it also defines address tags (see #define_user_address_tags) for the address and work_address
    def define_user_details_tags(name_base,options={})
      local=options[:local]
      if !local
        name_parts = name_base.split(":")
        local = name_parts[-1]
      end
      expansion_tag("#{name_base}:myself") { |t| t.locals.send(local) == myself }
      expansion_tag("#{name_base}:male") { |t| t.locals.send(local).gender == 'm' }
      expansion_tag("#{name_base}:female") { |t| t.locals.send(local).gender == 'f' }
      define_value_tag("#{name_base}:user_id") { |t| t.locals.send(local).id }
      define_value_tag("#{name_base}:profile") { |t| t.locals.send(local).user_profile_id }
      define_value_tag("#{name_base}:profile_name") { |t| t.locals.send(local).user_profile.name }
      define_h_tag("#{name_base}:first_name") { |t| t.locals.send(local).first_name }
      define_h_tag("#{name_base}:last_name") { |t| t.locals.send(local).last_name }
      define_h_tag("#{name_base}:salutation") { |t| t.locals.send(local).salutation }
      define_h_tag("#{name_base}:name") { |t| t.locals.send(local).name }
      define_h_tag("#{name_base}:email") { |t| t.locals.send(local).email } 
      define_h_tag("#{name_base}:cell_phone") { |t| t.locals.send(local).cell_phone }
      define_image_tag("#{name_base}:img") { |t| t.locals.send(local).image }
      define_image_tag("#{name_base}:second_img") { |t| t.locals.send(local).second_image }
      define_image_tag("#{name_base}:fallback_img") { |t| t.locals.send(local).second_image || t.locals.send(local).image }

      expansion_tag("#{name_base}:address") { |t| t.locals.address = t.locals.send(local).address }
      define_user_address_tags("#{name_base}:address")
      
      expansion_tag("#{name_base}:work_address") { |t| t.locals.work_address = t.locals.send(local).work_address }
      define_user_address_tags("#{name_base}:work_address")

    end

    # Defines address tags
    def define_user_address_tags(name_base,options={})
       local=options[:local]
      if !local
        name_parts = name_base.split(":")
        local = name_parts[-1]
      end

      define_value_tag("#{name_base}:display") { |t| t.locals.send(local).display(t.attr['separator'] || "<br/>") }
      
      %w(address address_2 company phone fax city state zip country).each do |fld|
        define_h_tag("#{name_base}:#{fld}") { |t| t.locals.send(local).send(fld) }
      end
      
    end

    def image_tag_helper(tag,img,tag_opts) #:nodoc:
      # Handle rollovers
      if img.is_a?(Array)
        rollover = img[1]
        object_id = img[2]
        img = img[0]
      end

      attr = tag.attr.clone
      if img 
        icon_size = attr.delete('size') || tag_opts[:size] || nil
        size = icon_size #%w(icon thumb preview small original).include?(icon_size) ?  icon_size : nil
        size = nil if size == 'original'
        img_size = img.image_size(size) || []
        shadow = attr.delete('shadow')
        align = attr.delete('align') 
        field = attr.delete('field')

        case field
        when 'width':
          img_tag = img_size[0].to_s
        when 'height':
          img_tag = img_size[1].to_s
        when 'dimensions':
          img_tag =  "width='#{img_size[0].to_s}' height='#{img_size[1].to_s}'"
        when 'src':
          img_tag = img.url(size)
        else
          if shadow
            shadow_align = align
            border_amt = (attr.delete('border') || 1).to_i
            if(align == 'left')
              border = "0 #{border_amt}px #{border_amt}px 0px"
            elsif(align == 'right')
              border = "0 0 #{border_amt}px #{border_amt}px"
            else
              border = 0
            end
          else
            attr['align'] = align
            border_amt = (attr.delete('border') || 1).to_i
            attr['style'] = (!attr['style'].blank?) ? attr['style'] + ';' : ''
            if(align == 'left')
              attr['style'] += "margin: 0 #{border_amt}px #{border_amt}px 0px;"
            elsif(align == 'right')
              attr['style'] += "margin: 0 0 #{border_amt}px #{border_amt}px"
            end
          end

          img_url = img.url(size)
          img_opts =  { :src => img_url,:width => img_size[0],:height => img_size[1] }
          attr.symbolize_keys!
          if attr[:width] || attr[:height]
            img_opts.delete(:width)
            img_opts.delete(:height)
          end
          unless img_size[0] && img_size[0].to_i > 1 && img_size[1].to_i > 1
            img_opts.delete(:width)
            img_opts.delete(:height)
          end
          tag_opts = attr.merge(img_opts)
          if rollover
            tag_opts[:onmouseover] = "WebivaMenu.swapImage(this,'#{jvh img_url}','#{jvh  rollover.url(size)}','#{object_id}'); " + tag_opts[:onmouseover].to_s
            tag_opts[:onmouseout] = "WebivaMenu.restoreImage(this,'#{object_id}'); " + tag_opts[:onmouseout].to_s
            preload = "<script>WebivaMenu.preloadImage('#{jvh rollover.url(size)}');</script>"
          end
          img_tag =  tag('img',tag_opts) + preload.to_s
          img_tag = "<div style='float:#{shadow_align}; margin:#{border}; #{attr['style']}'><div style='width:#{img_size[0] + 12}px; float:#{shadow_align};' class='cms_gallery_shadow'><div><p>" + img_tag + "</p></div></div></div>" if img_size[0] && shadow
        end
        if tag.single?
          img_tag
        else
          tag.locals.value = img_tag
          tag.expand
        end            
      else
        nil
      end

    end
    
    # Defines an image tag that expects a DomainFile to be returned from
    # the yielded block and will create an html img tag 
    def define_image_tag(tag_name,local_obj=nil,attribute=nil,tag_opts={})
      define_tag tag_name + ":value" do |tag|
        tag.locals.value
      end
      
      obj_value = Proc.new() do |tag|
        if local_obj
          obj = tag.locals.send(local_obj)
          if(obj)
            if block_given?
              if attribute
                img = yield obj.send(attribute), tag
              else
                img = yield obj,tag
              end
            elsif attribute
              img = obj.send(attribute)
            else
              img = obj
            end
          end
        else
          img = yield tag
        end
      end
      tag_parts = tag_name.split(":")
      tag_parts[-1] = "no_" + tag_parts[-1]
      define_tag tag_parts.join(":") do |tag|
        img = obj_value.call(tag)
        img ? nil : tag.expand
      end
      
      define_tag tag_name do |tag|
        img = obj_value.call(tag)
        image_tag_helper(tag,img,tag_opts)
      end
    end
    
    def define_form_tag(frm,name) #:nodoc:
      define_tag name do |tag|
        expand = block_given? ? yield : true
        if expand
          tag.locals.form = frm
          "<form action='' method='post'><CMS:AUTHENTICITY_TOKEN/>" + tag.expand + "</form>"
        else
          nil
        end
      end
    end

    def define_ajax_form_for_tag(name,arg,options = {},&block)
      options[:html] ||= {}
      options[:html][:onsubmit] ||= ''
      options[:html][:onsubmit] += " new Ajax.Updater('cmspara_#{paragraph.id}','#{ajax_url}',{ evalScripts: true, parameters: Form.serialize(this) }); return false;"
      define_form_for_tag(name,arg,options,&block)
      require_js('prototype')
    end

    # Creates a cms_unstyled_form_for object that can be used 
    # in combination with define_field_tag to allows users to 
    # custom style a form
    def define_form_for_tag(name,arg,options = {})
      frm_obj = options[:local] || 'form'
      define_tag name do |tag|
        obj = yield tag if block_given?
        if obj || !block_given?
          opts = options.clone
          opts.symbolize_keys!
          if obj.is_a?(Hash)
            arg_obj = obj.delete(:object)
            opts = opts.merge(obj)
            obj = arg_obj
            opts.symbolize_keys!
          end
          opts[:url] ||= ''
          frm_opts = opts.delete(:html) || { }
          frm_opts[:method] ||= 'post'
          html_options = html_options_for_form(options.delete(:url),frm_opts)
          html_options['action'] ||= ''
          if pch = opts.delete(:page_connection_hash)
            pch = "<input type='hidden' name='page_connection_hash' value='#{pch}' />"
          end
          frm_tag = tag(:form,html_options,true) + (frm_opts[:method] == 'post' ? "<CMS:AUTHENTICITY_TOKEN/>" : '')+ pch.to_s + opts.delete(:code).to_s
          cms_unstyled_fields_for(arg,obj,opts) do |f|
            tag.locals.send("#{frm_obj}=",f)
            frm_tag + tag.expand + "</form>"
          end
        else
          nil
        end
      end
    end
    
    def define_fields_for_tag(name,arg,options = {}) #:nodoc:
      frm_obj = options.delete(:local) || 'form'
      define_tag name do |tag|
        obj = yield tag
        opts = options.clone
        opts[:url] ||= ''
        if obj || !block_given?
          cms_unstyled_fields_for(arg,obj,opts) do |f|
            tag.locals.send("#{frm_obj}=",f)
            opts.delete(:code).to_s + tag.expand
          end
        else
          nil
        end
      end
    end

    def define_publication_form_error_tag(name,publication,options={})#:nodoc:
      frm_obj = options.delete(:local) || 'form'
      define_value_tag name do |t|
        output = []
        frm = t.locals.send(frm_obj)
        publication.content_publication_fields.each do |fld|
          err = frm.output_error_message(fld.label,fld.content_model_field.field)
          output << err if err
        end
        output.join()
      end
    end
    
    # Allows users to display the full error messages of a form_for_tag
    def define_form_error_tag(name,options={})
      frm_obj = options.delete(:local) || 'form'
      name_parts = name.split(":")
      name_base = name_parts[-1]
      
      define_tag "#{name_parts[0..-2].join(":")}:no_#{name_base}" do |t|
        frm = t.locals.send(frm_obj)
        if frm && frm.object && frm.object.errors && frm.object.errors.length > 0
          nil
        else
          t.expand
        end
      end
          
      define_tag name do |tag|
        if block_given?
          objs = yield tag
          objs = [ objs ] unless objs.is_a?(Array)
        else
          frm = tag.locals.send(frm_obj)
          objs = [ frm.object ] if frm && frm.object
        end
        objs ||= []
        objs = objs.compact
        error_count = objs.inject(0) { |acc,obj| acc + obj.errors.length } 
        if error_count > 0 
          messages = objs.inject([]) { |acc,obj| acc + obj.errors.full_messages }.join(tag.attr['separator'] || "<br/>")
          if tag.single?
            messages
          else
            tag.locals.value = messages
            tag.expand           
          end          
        else
          nil
        end
      end
      
      define_tag "#{name}:value" do |tag|
        tag.locals.value            
      end
    end
    
    # Defines a submit button tag
    def define_button_tag(name,options={})
      onclick = options.delete(:onclick)
      define_tag name do |t|
        name = options[:name] || t.attr['name'] || 'commit'
        if  !block_given? || yield(t)
          if(t.attr['type'].to_s == 'image')
            tag('input',
                :type => 'image',
                :class => 'submit_tag submit_image',
                :name => name,
                :value => t.attr['value'] || options[:value] || 'Submit',
                :src => t.expand,
                :id => t.attr['id'] || options[:id],
                :align => :absmiddle,
                :onclick => onclick )
          else
            tag('input', { :type => 'submit',
                  :class => 'submit_tag',
                  :name => name,
                  :id => t.attr['id'] || options[:id],
                  :value => t.single? ?
                  (t.attr['value'] || options[:value] || 'Submit') : t.expand,
                  :onclick => onclick })
          end
        else
          nil
        end
      end
    end
    
    def define_delete_button_tag(name,options={}) #:nodoc:
      frm_obj = options[:local] || 'form'
      define_tag name do |t|
        if t.locals.send(frm_obj).object.id.blank?
          nil
        else
          <<-TAGS 
            <input type='hidden' name='#{t.locals.send(frm_obj).object_name}_delete' value='0' id='#{t.locals.send(frm_obj).object_name}_delete' />
            <input type='submit' onclick='$("#{t.locals.send(frm_obj).object_name}_delete").value="1"; return true;' value='#{vh t.expand}'/>
          TAGS
        end
      end
    end
    
  def define_submit_tag(tag_name,options = {:default => 'Submit'.t }) #:nodoc:

    self.define_tag tag_name do |tag|
      output =''
      if tag.single?
        txt = tag.attr['value'] || options[:default]
        output ="<input type='submit' name='button' value='#{vh txt}'/>"
      else
                        
        if !block_given? || yield
          if tag.attr['type'] == 'image'
            output = "<input type='image' src='#{vh tag.expand}' align='absmiddle'/>"
          else
            output = "<input type='submit' class='submit_tag' name='button' value=\"#{tag.expand}\"/>"
          end
        else
          output = nil
        end
      end
      if(options.has_key?(:form))
        if !options[:form]
          nil
        else
          "<form action='#{options[:form]}' method='#{options[:method]||'get'}'>" + output + "</form>"
        end
      else
        output
      end
    end
  end
    
  # Defines a link tag that expects either a string representing the
  # href of a link or a hash with additional tag attributes (like :noclick)
  # 
  # For example:
  #
  #     define_link_tag('result') { |t| '/result' }
  #
  # would define 3 tags:
  # [<cms:result_link>]
  #   Block tag that creates s <a>..</a> tag wrapping it's content
  # [<cms:result_url/>]
  #   Value tag that returns the url of the link tag
  # [<cms:result_href/>]
  #   Value tag that returns a href="url.." tag
  def define_link_tag(name,options={})
    name_base = name[-1..-1] == ":" ? name : name + "_"
    
    define_value_tag(name_base + "url") do |tg| 
      url = yield tg  
      if url.is_a?(Hash)
        url[:href]
      else
        url
      end
    end
    
    define_tag(name_base + "link") do |tg|
      attr = tg.attr.clone
      selected = attr.delete('selected_class')
      url = yield(tg)
      if url.blank?
        nil
      elsif url.is_a?(Hash)
        url_selected = url.delete(:selected)
        url[:class] = selected if selected && url_selected
        tag('a',attr.merge(options).merge(url),true) + tg.expand + "</a>" 
      else
        tag('a',attr.merge(options).merge({ :href => url }),true) + tg.expand + "</a>" 
      end
    end
    define_value_tag(name_base + "href") do |tg| 
      url = yield tg  
      if url.is_a?(Hash)
        url.to_a.map { |elm| "#{elm[0]}='#{vh elm[1]}'" }.join(" ")
      else
        "href='#{url}'"
      end
    end
  end
  
  def define_captcha_tag(name,options={})  #:nodoc:
    define_value_tag(name) do |t| 
      captcha = yield t
      if captcha
        captcha.generate(t.attr.merge(options))
      else
        nil
      end
    end

    define_value_tag(name+'_error') do |t|
      captcha = yield t
      if captcha
        captcha.valid? ? nil : (t.attr['message'] || 'Captcha is invalid')
      else
        nil
      end
    end
  end
    
    # Defines a field tag used with define_form_for_tag
    # Most options are passed directly through to the appropriate field options
    # with the exception of the :control option which defines that control
    # that should be used (any of the controls in StyleFormBuilderGenenerator,
    # :text_field, :text_area, :radio_buttons, etc )
    #
    # If the control type expects options. Those can be returned via a block
    # or from the :options option
    def define_field_tag(name,options={},&block)
      define_form_field_tag(name,options,&block)    
    end

    def form_field_tag_helper(t,frm,control_type,field_name,options={},&block) #:nodoc:
      options=options.clone
      atr = t.attr.symbolize_keys
      # Block contains the options for an options control 
      # otherwise it just wraps the output
      options_control = %w(select radio_buttons check_boxes).include?(control_type.to_s)
      field_opts = options.delete(:options) if options_control
            
      
      if control_type == 'select'
        options[:id] ||= "#{frm.object_name}_#{field_name}"
      end
      
      empty_click = atr.delete('prefill')
      if empty_click
        atr['onfocus'] = "if(this.value=='#{jvh empty_click}') this.value=''";
        atr['onblur'] = "if(this.value=='') this.value='#{jvh empty_click}'";
        frm.object.send("#{field_name}=",empty_click) if frm.object.send(field_name).blank?
      end

      if options_control
        if opt_names = atr.delete(:options)
          
          names = opt_names.split(',').collect { |elm| elm.blank? ? nil : elm.strip }.compact
          idx = -1
          control_opts =  field_opts.map do |elm| 
            idx+=1
            [ names[idx] || elm[0], elm[1] ]
          end
        elsif field_opts
          control_opts = field_opts
        else
          control_opts = block.call(t)
        end
        
        if control_type.to_s == 'select'
          output = frm.select_tag("#{frm.object_name}[#{field_name}]",options_for_select(control_opts,frm.object.send(field_name)),options.merge(atr))
        else

          output = frm.send(control_type,field_name,control_opts,options.merge(atr))
        end
      else
        output = frm.send(control_type,field_name,options.merge(atr))
      end
      
      # Block contains the options for an options control 
      # otherwise it just wraps the output
      if block && (!options_control || field_opts)
        block.call(t,output)
      else
        output
      end
    end
    
    # Defines an error tag for an individual field
    def form_field_error_tag_helper(t,frm,field_name)
      errs = frm.object.errors.on(field_name)
      if errs.is_a?(Array)
        errs = errs.uniq
        val = errs.collect { |msg| 
          (t.attr['label'] || field_name.to_s.humanize) + " " + msg.t + "<br/>"
        }.join("\n")
      elsif errs
        val =(t.attr['label'] || field_name.to_s.humanize) + " " + errs.t
      end
      
      val
    end

    # Fields is a list array of arrays like:
    #  [ :tag_name, "Label", :field_control, :field_name, options = {} ]
    def define_form_fields_tag(base,fields,options = {})
      local = options[:local] || 'form'

      fields.each do |fld|
          define_form_field_tag("#{base}:#{fld[0]}",fld[4].merge(:label => fld[1], :control => fld[2], :field => fld[3] ))
      end

      define_loop_tag(base,nil,:local => 'field') { |t| fields }

      define_tag("#{base}:item") do |t|
        tag_name = t.attr['tag'] || 'li'
        if !t.single?
          "<#{tag_name} class='#{t.locals.field[2]}'>" + t.expand + "</#{tag_name}>"
        else 
          "<#{tag_name} class='#{t.locals.field[2]}'>" + form_fields_helper(t,local,t.locals.field) +  "</#{tag_name}>"
        end
      end

      define_tag("#{base}:item:label") { |t| form_fields_label_helper(t,local,t.locals.field) }

      define_tag("#{base}:item:control") do |t|
        form_field_tag_helper(t,t.locals.send(local),t.locals.field[2],t.locals.field[3],t.locals.field[4])
      end

      define_value_tag "#{base}:error" do |t|
        form_field_error_tag_helper(t,t.locals.send(local),t.locals.field[3])
      end

    end

    def form_fields_label_helper(t,local,field)
      object_id = field[2] if ![:radio_buttons,:check_boxes].include?(field[2])
      frm = t.locals.send(local)
      req = field[4][:required] ? "<em>*</em>" : ""
      label = field[1]
      if object_id 
        "<label for='#{frm.object_name}_#{object_id}'>#{label.to_s + req}</label>"
      else
        "<label>#{label}</label>"
      end
    end

    def form_fields_helper(t,local,field)
      form_fields_label_helper(t,local,field) + 
        form_field_tag_helper(t,t.locals.send(local),field[2],field[3],field[4])
    end

    def define_form_field_tag(name,options={},&block) #:nodoc:
      options = options.clone
      
      name_parts = name.split(":")
      pre_tag = name_parts[0..-2].join(":")
      pre_tag += ":" unless pre_tag.blank?
      tag_name = name_parts[-1]
      
      
      control_type = options.delete(:control) || 'text_field'
      field_name = options.delete(:field) || tag_name
      label = options.delete(:label) || field_name.to_s.humanize
      options[:class] ||= control_type
      frm_obj = options[:local] || :form
      required = options.delete(:required)
      
      if control_type != 'radio_buttons' && control_type != 'check_boxes'
        object_id = field_name
      else
        object_id = nil
      end

      define_tag "#{pre_tag}#{tag_name}_label" do |t|
        if object_id
          frm = t.locals.send(frm_obj)
          req = required ? "<em>*</em>" : ""
          "<label for='#{frm.object_name}_#{object_id}'>#{t.single? ? label.to_s + req : t.expand}</label>"
        else
          t.single? ? label : t.expand
        end
      end
      
     
      define_tag "#{pre_tag}#{tag_name}" do |t|
        form_field_tag_helper(t,t.locals.send(frm_obj),control_type,field_name,options,&block)
      end
    
      define_value_tag "#{pre_tag}#{tag_name}_error" do |t|
        form_field_error_tag_helper(t,t.locals.send(frm_obj),field_name)
      end
    end

    def has_many_field_helper(level,t,value,idx) #:nodoc:
      output = ''
     
      if value.is_a?(Hash)
        t.locals.has_many_grouping=value[:name]
        t.locals.has_many_entry=nil
        output << t.expand

        output << has_many_field_helper(level,t,value[:items],idx)
        
      elsif value.is_a?(Array)
        if value[0].is_a?(Hash)
          value.each_with_index do |itm,idx2|
            t.locals.first = idx2 == 0
            t.locals.last =  itm == value.last
            t.locals.index = idx2+1
            t.locals.has_many_level = level
            output << has_many_field_helper(level+1,t,itm,idx2)
          end
        else
          t.locals.has_many_grouping = nil
          t.locals.has_many_entry = value
          output << t.expand
        end
      end
      output
    end

    # Defines a form and a list of fields that represent the exposed filters
    # in a publication - should be used only in webiva_custom_feature
    def define_publication_filter_form_tags(prefix,arg,publication,options={}) 
      define_button_tag("#{prefix}:submit",:value => 'Search')
      define_button_tag("#{prefix}:clear",:value => 'Clear',:name => "clear_#{arg}")

      define_form_for_tag(prefix,arg, :local => arg) {  |t|  yield(t)[0] }

      define_publication_filter_fields_tags(prefix,arg,publication,options)
    end

    # Defines a list of fields that represent the exposed filters
    # in a publication - should be used only in webiva_custom_feature
    def define_publication_filter_fields_tags(prefix,arg,publication,options={}) 
      
      if block_given?
        define_expansion_tag("#{prefix}_search") { |t| yield(t)[1] }
      else
        define_expansion_tag("#{prefix}_search") { |t| false }
      end

   
      
      publication.content_publication_fields.each do |fld|
        if !fld.options.filter.blank? && fld.options.filter_options.include?('expose')
          fld.filter_variables.each do |var|
            define_value_tag("#{prefix}:#{var}_value") do |t|
              obj = t.locals.send(arg).object
              obj.send(var)
            end
          end
          fld.filter_names.each do |variable|
          
            define_tag("#{prefix}:#{fld.content_model_field.feature_tag_name}_#{variable}") do |t|
              fld.filter_options(t.locals.send(arg),variable,t.attr)
            end
          end
        end
      end
    end


    def define_domain_prefix_tag
      define_tag("domain_prefix") { |t| (request.ssl? ? "https://" : "http://") + Configuration.full_domain }
    end
    
    
    def define_content_model_fields_value_tags(prefix,content_model_fields,options = {})
      c = self
     local = options.delete(:local) || 'entry'
      content_model_fields.each do |fld|
        fld.site_feature_value_tags(c,prefix,:full,:local => local)
      end
    end

    def define_content_model_value_tags(prefix,content_model,options = {})
      define_content_model_fields_value_tags(prefix,content_model.content_model_fields,options)
    end

    # Defines a list of tags based on a passed-in publication
    # Can only be used in webiva_custom_feature
    def define_publication_field_tags(prefix,publication,options = {})
      c = self

      frm_obj = options.delete(:local) || 'form'
      pub_options = publication.options.to_hash
      size = pub_options[:field_size] || nil;

      publication.content_publication_fields.each do |fld|
        if fld.content_model_field.data_field?
          tag_name = fld.content_model_field.feature_tag_name

          if fld.field_type=='input'
            c.define_tag "#{prefix}:#{tag_name}" do |t|
              opts = { :label => fld.label, :size => size }.merge(fld.data)
              opts[:size] = t.attr['size'] if t.attr['size']
              opts = opts.merge(t.attr)
              opts.symbolize_keys!
              fld.form_field(t.locals.send(frm_obj),opts)
            end

            c.define_tag("#{prefix}:#{tag_name}_label") do |t|
              req = fld.required? ? "<em>*</em>" : ""
              req = '' if t.attr['no_required']
              label =fld.label
              frm = t.locals.send(frm_obj)
              object_id = fld.content_model_field.field
              "<label for='#{frm.object_name}_#{object_id}'>#{t.single? ? (label.to_s + req) : t.expand }</label>"
            end


            c.value_tag "#{prefix}:#{tag_name}_value" do |t|
              fld.content_value(t.locals.send(frm_obj).object)
            end
            
            c.value_tag "#{prefix}:#{tag_name}_display" do |t|
              fld.content_display(t.locals.send(frm_obj).object,:full,t.attr)
            end
            
            
            c.value_tag "#{prefix}:#{tag_name}_error" do |t|
              t.locals.send(frm_obj).output_error_message(fld.label,fld.content_model_field.field)
            end
          elsif fld.field_type == 'value'
            fld.content_model_field.site_feature_value_tags(c,prefix,:full,:local => frm_obj  )
          end
        end
      end

      if publication.form?
               
        c.loop_tag("#{prefix}:field") do |t|
          fields = publication.content_publication_fields.select { |fld| fld.field_type == 'input' && fld.content_model_field.data_field? }
          if t.attr['except']
            except_fields = t.attr['except'].split(",").map { |elm| elm.blank? ? nil : elm.strip }.compact
            fields = fields.select { |elm| !except_fields.include?(elm.content_model_field.feature_tag_name) }
          end
          if t.attr['fields']
            only_fields = t.attr['fields'].split(",").map { |elm| elm.blank? ? nil : elm.strip }.compact
            fields = fields.select { |elm| only_fields.include?(elm.content_model_field.feature_tag_name) }
          end
          fields
        end

        define_tag("#{prefix}:field:item") do |t|
          tag_name = t.attr['tag'] || 'li'
          if !t.single?
            "<#{tag_name} class='#{t.locals.field.content_model_field.field_type}_model_field' >" + t.expand + "</#{tag_name}>"
          else 
            "<#{tag_name} class='#{t.locals.field.content_model_field.field_type}_model_field' >" + publication_form_fields_helper(t,frm_obj,t.locals.field) +  "</#{tag_name}>"
          end
        end

        c.value_tag("#{prefix}:field:label") do |t|
          req = t.locals.field.required? ? "<em>*</em>" : ""
          label = t.locals.field.label
          frm = t.locals.send(frm_obj)
          object_id = t.locals.field.content_model_field.field
          "<label for='#{frm.object_name}_#{object_id}'>#{label.to_s + req}</label>"
        end

        c.value_tag("#{prefix}:field:required") do |t|
          t.locals.field.required?
        end

        c.value_tag("#{prefix}:field:control") do |t|
          opts = { :label => t.locals.field.label, :size => size }.merge(t.locals.field.data)
          opts[:size] = t.attr['size'] if t.attr['size']
          t.locals.field.form_field(t.locals.send(frm_obj),opts.merge(t.attr))
        end
        
        c.value_tag("#{prefix}:field:error") do |t|
          c.form_field_error_tag_helper(t,t.locals.send(frm_obj),t.locals.field.content_model_field.field)
        end
      end

    end

    def publication_form_fields_helper(t,frm_obj,field)
      req = field.required? ? "<em>*</em>" : ""
      label = field.label
      frm = t.locals.send(frm_obj)
      object_id = field.content_model_field.field
      opts = { :label => t.locals.field.label }.merge(t.locals.field.data)
      opts[:size] = t.attr['size'] if t.attr['size']

      "<label for='#{frm.object_name}_#{object_id}'>#{label.to_s + req}</label>" +
      field.form_field(t.locals.send(frm_obj),opts.merge(t.attr.symbolize_keys))
    end

    # Defines a page_list tag called pages on the base as well as tags for 
    # total_results, first_results and last_result
    def define_results_tags(tag_base,options ={ },&block)
      
      define_pagelist_tag("#{tag_base}:pages",options,&block)

      self.value_tag("#{tag_base}:total_results") do |tag|
        page_data = yield(tag)
        page_data[:total]
      end

      self.value_tag("#{tag_base}:first_result") do |tag|
        page_data = yield(tag)
        page_data[:first]
      end

      self.value_tag("#{tag_base}:last_result") do |tag|
        page_data = yield(tag)
        page_data[:last]
      end
      
    end



    # Given the pages hash output of DomainModel#self.paginate 
    # it will display a list of pages 
    # TODO: rewrite for customization
    def define_pagelist_tag(tag_name,options = {}) 
      

      self.define_tag tag_name do |tag|
        page_data = yield(tag)
        if page_data
          page = page_data[:page]
          path = page_data[:path] || ''
          pages = page_data[:pages] || 1

          field = (path.to_s.include?("?") ? '&' : '?') + (options[:field] || 'page')

          display_pages = options[:pages_to_display] || 2
          
          last_page = tag.attr['last'] || "&lt; &lt;"
          next_page = tag.attr['next'] || "&gt; &gt;"
          
          result = ''
          
          if pages && pages > 1
            
            # Show back button
            if page > 1
              result += "<a href='#{path}#{field}=#{page-1}'>#{last_page}</a> &nbsp;&nbsp;"
            end
            # Find out the first page to show
            start_page = (page - display_pages) > 1 ? (page - display_pages) : 1
            end_page = (start_page + (display_pages*2))
            if end_page > pages
              start_page -= end_page - pages - 1
              start_page = 1 if start_page < 1 
              
              end_page = pages
            end
            
            if start_page == 2
              result += " <a href='#{path}#{field}=1'> 1 </a> "
            elsif start_page > 2
              result += " <a href='#{path}#{field}=1'> 1 </a> .. "
            end
            
            (start_page..end_page).each do |pg|
              if pg == page
                result += " <b> #{pg} </b> "
              else
                result += " <a href='#{path}#{field}=#{pg}'> #{pg} </a> "
              end
            end
            
            if end_page == pages - 1
              result += " <a href='#{path}#{field}=#{pages}'> #{pages} </a> "
            elsif end_page < pages - 1
              result += " .. <a href='#{path}#{field}=#{pages}'> #{pages} </a> "
            
            end
            
            # Next Button
            if page < pages
              result += " &nbsp;&nbsp;<a href='#{path}#{field}=#{page+1}'>#{next_page}</a> "
            end
          end
          
          result        
        else
          nil
        end
        
      end      
    end

    # Defines the a list of tags that are available in a loop tag
    def define_position_tags(prefix=nil)
        prefix += ':' if prefix
        prefix = prefix.to_s
        define_tag(prefix + 'index') { |tag| (tag.attr['modulus'] ?  ((tag.locals.index) % tag.attr['modulus'].to_i)+1 : tag.locals.index)}
        define_tag(prefix + 'at') { |tag| tag.attr['index'].to_i == tag.locals.index ? tag.expand : nil }
        define_tag(prefix + 'not_at') { |tag| tag.attr['index'].to_i != tag.locals.index ? tag.expand : nil }
        define_tag(prefix + 'first') { |tag| tag.locals.first ? tag.expand : '' }
        define_tag(prefix + 'last') { |tag| tag.locals.last ? tag.expand : '' }
        define_tag(prefix + 'odd') { |tag| tag.locals.index.odd? ? tag.expand : '' }
        define_tag(prefix + 'even') { |tag| tag.locals.index.even? ? tag.expand : '' }
        define_tag(prefix + 'not_first') { |tag| !tag.locals.first ? tag.expand : '' }
        define_tag(prefix + 'not_last') { |tag| !tag.locals.last ? tag.expand : '' }
        define_tag(prefix + 'middle') { |tag| ( !tag.locals.first && !tag.locals.last ) ? tag.expand : '' }
        define_tag(prefix + 'not_middle') { |tag| (tag.locals.first || tag.locals.last)  ? tag.expand : '' }
        define_tag(prefix + 'multiple') { |tag| ( (tag.locals.index + (tag.attr['offset'] || 0).to_i ) % (tag.attr['value'] || 2).to_i ) == 0 ? tag.expand : '' }
        define_tag(prefix + 'before') { |tag| (tag.locals.index < tag.attr['index'].to_i)  ? tag.expand : '' }
        define_tag(prefix + 'after') { |tag| (tag.locals.index > tag.attr['index'].to_i)  ? tag.expand : '' }
    end    
    
    # Called inside of a loop_tag for a customized iteratation over a list
    def each_local_value(arr,tag,field = 'value')
      output = ''
      return nil unless arr.is_a?(Array)
      last = arr.length-1
      arr.each_with_index do |value,idx|
        tag.locals.send("#{field}=",value)
        tag.locals.first = idx == 0
        tag.locals.last =  idx == last
        tag.locals.index =  idx+1
        if block_given?
          data = yield value, tag
          output += data.to_s
        else
          output += tag.expand
        end
      end
      output
    end
    
    def define_post_button_tag(tag_name,options = {}) #:nodoc:
      button_value = options[:button] || 'Submit'
      method = options[:method] || 'post'
      define_tag tag_name do |tag|
        onsubmit = tag.attr['confirm'] ? "onsubmit='return confirm(\"#{jvh tag.attr['confirm']}\");'" : ''
        cls = tag.attr['class'] || 'post_button'
        url = yield tag
        
        if url.blank? 
          nil
        elsif tag.attr['icon'] || (tag.attr['type'] == 'image')
            img_src = (tag.single? ? tag.attr['icon'] : tag.expand)
            "<form class='post_button_form' style='display:inline;' action='#{vh url}' #{onsubmit} method='#{method}'><CMS:AUTHENTICITY_TOKEN/><input class='#{cls}' type='image' value='submit' src='#{vh img_src}'/></form>"
        else
          button_value = (tag.attr['value'] || (tag.single? ? button_value : tag.expand))
          "<form class='post_button_form'  style='display:inline;' action='#{vh url}'  #{onsubmit}  method='#{method}'><CMS:AUTHENTICITY_TOKEN/><input class='#{cls}' type='submit' value='#{qvh(button_value)}'/></form>"
        end      
      end
    end
    
    def define_login_block(tag_name,login_error) #:nodoc:
      define_expansion_tag(tag_name) do |tag|
        user = yield
        user.id ? false : true
      end
      
      define_tag(tag_name + ":form") do |tag|
        "<form action='' method='post'>"  + tag.expand + "</form>"
      end
      
      define_tag(tag_name + ":form:email") do |tag|
        "<input type='text' size='#{tag.attr['size'] || 40}' name='login[email]' value=''/>"
      end
      define_tag(tag_name + ":form:password") do |tag|
        "<input type='password' size='#{tag.attr['size'] || 40}' name='login[password]' value=''/>"
      end
      define_tag(tag_name + ":error") do |tag|
        login_error ? tag.expand : nil
      end
      
      define_button_tag(tag_name + ":button")
    end 
    
    def define_media_tag(name, options={}, &block)
      define_value_tag(name) do |tag|
        file = yield(tag)

	if SiteModule.module_enabled?('media') && file
	  opts = options.clone.merge(tag.attr.symbolize_keys)
	  ext = file.extension.to_s.downcase

    @player_idx ||= 0
    @player_idx += 1

	  case ext
	  when 'mp3'
	    media_options = Media::MediaController::AudioOptions.new(opts)
	    media_options.media_file_id = file.id
	    media_options.media_file = file
	    container_id = "#{media_options.media_type}_#{paragraph.id}_#{@player_idx}"
	    media_options.player.headers(self)
	    media_options.player.render_player(container_id)
	  when 'flv'
	    media_options = Media::MediaController::VideoOptions.new(opts)
	    media_options.media_file_id = file.id
	    media_options.media_file = file
	    container_id = "#{media_options.media_type}_#{paragraph.id}_#{@player_idx}"
	    media_options.player.headers(self)
	    media_options.player.render_player(container_id)
	  when 'mov'
	    width = (tag.attr['width'] || 320).to_i
	    height = (tag.attr['height'] || 260).to_i
	    "<embed src='#{file.url}' width='#{width}' height='#{height}' autoplay='false' />"
	  else
	    message = tag.attr['link'] || file.name
	    "<a href='#{file.url}'>#{message}</a>"
	  end
	end
      end
    end

    def define_header_tag(name)
      define_tag(name) do |tag|
        content = yield(tag) if block_given?
        content ||= tag.expand unless tag.single?
        html_include(:head_html, content) unless content.blank?
        nil
      end
    end

    def define_meta_tag(name, options={})
      define_tag(name) do |tag|
        content = yield(tag) if block_given?
        content ||= tag.expand unless tag.single?
        content ||= tag.attr['content']

        if tag.attr['name']
          case tag.attr['name'].downcase
          when 'description'
            html_include(:meta_description, content)
          when 'keywords'
            html_include(:meta_keywords, content)
          end
        else
          opts = options.stringify_keys
          opts.merge! tag.attr
          opts['content'] = content
          html_include(:head_html, tag(:meta, opts))
        end
        nil
      end
    end

    # get versions of all the define_... methods without the define
    skip_methods = %w(define_form_tag define_tag)
    instance_methods.each do |method_name|
      if !skip_methods.include?(method_name) && method_name =~ /define\_(.*)/
        alias_method $1.to_sym, method_name.to_sym
      end
    end
  end  
  
  # Class used to automatically document the tags available in a feature
  class FeatureDocumenter
    attr_reader :method_list 
    
    def initialize(renderer) #:nodoc:
      @method_list = []
      yield self
    end
    
    def define_loop_tag(name,plural=nil,options={}) #:nodoc:
      name_parts = name.split(":")
      name_base = name_parts[-1]
      plural = name_base.pluralize unless plural
      name_parts[-1] = plural
      
      expansion_tag = name_parts.join(":")
      define_iteration_tag(name)
      define_expansion_tag(expansion_tag)
    end
    
    def define_link_tag(name,options={})#:nodoc:
      name_base = name[-1..-1] == ":" ? name : name + "_"
    
      define_value_tag(name_base + "url")
      define_block_tag(name_base + "link")
      define_value_tag(name_base + "href")
    end

    def define_user_tags(tag_name,options = {})
      expansion_tag(tag_name)
      expansion_tag(tag_name + ":logged_in")
      define_value_tag(tag_name + ":name")
      define_value_tag(tag_name + ":email")
      define_value_tag(tag_name + ":username")
      define_value_tag(tag_name + ":first_name")
      define_value_tag(tag_name + ":last_name")
      define_value_tag(tag_name + ":profile")
      define_value_tag(tag_name + ":profile_name")
      expansion_tag(tag_name + ":myself")
      define_image_tag(tag_name + ":img")
    end

    def define_user_details_tags(name_base,options={}) #:nodoc:
      expansion_tag("#{name_base}:myself")
      expansion_tag("#{name_base}:male")
      expansion_tag("#{name_base}:female")
      define_value_tag("#{name_base}:user_id")
      define_value_tag("#{name_base}:first_name")
      define_value_tag("#{name_base}:last_name") 
      define_value_tag("#{name_base}:name")
      define_value_tag("#{name_base}:email")
      define_image_tag("#{name_base}:img") 
      define_image_tag("#{name_base}:second_img") 
      define_image_tag("#{name_base}:fallback_img")

      expansion_tag("#{name_base}:address") 
      define_user_address_tags("#{name_base}:address")
      
      expansion_tag("#{name_base}:work_address")
      define_user_address_tags("#{name_base}:work_address")

    end

    def define_publication_filter_form_tags(prefix,arg,publication,options={}) #:nodoc
      define_form_for_tag(prefix)
      define_button_tag("#{prefix}:submit",:value => 'Search')
      define_button_tag("#{prefix}:clear",:value => 'Clear',:name => "clear_#{arg}")      
      define_publication_filter_fields_tags(prefix,arg,publication,options)
    end

    def define_publication_filter_fields_tags(prefix,arg,publication,options={}) #:nodoc:

      define_expansion_tag("#{prefix}_search")
      

      define_field_fields_tag("#{prefix}:fields")
      publication.content_publication_fields.each do |fld|
        if !fld.options.filter.blank? && fld.options.filter_options.include?('expose')

          fld.filter_variables.each do |var|
            define_value_tag("#{prefix}:#{var}_value")
          end
          fld.filter_names.each do |variable|
            define_tag("#{prefix}:#{fld.content_model_field.feature_tag_name}_#{variable}")
          end

        end
      end
    end

    def define_content_model_fields_value_tags(prefix,content_model_fields,options = {})
      c = self
      content_model_fields.each do |fld|
        fld.site_feature_value_tags(c,prefix,:full,:local => 'entry')
      end
    end

    def define_content_model_value_tags(prefix,content_model,options = {})
      define_content_model_fields_value_tags(prefix,content_model.content_model_fields,options)
    end
    
    def define_user_address_tags(name_base,options={}) #:nodoc:
      define_value_tag("#{name_base}:display")
      
      %w(address address_2 company phone fax city state zip country).each do |fld|
        define_h_tag("#{name_base}:#{fld}")
      end
      
    end

    def define_h_tag(tg,field='value',options={}) #:nodoc:
      @method_list << [ "Escaped value tag",tg ]
    end


    def define_publication_field_tags(prefix,publication,options={}) #:nodoc:
      c = self
      local = options.delete(:local) || 'entry'
      
      publication.content_publication_fields.each do |fld|
        if fld.content_model_field.data_field?
          tag_name = fld.content_model_field.feature_tag_name

          if fld.field_type=='input'
            define_form_field_tag "#{prefix}:#{tag_name}"
            value_tag "#{prefix}:#{tag_name}_value"
            value_tag "#{prefix}:#{tag_name}_display"
            value_tag "#{prefix}:#{tag_name}_label"
            define_form_field_error_tag "#{prefix}:#{tag_name}_error"
          elsif fld.field_type == 'value'
            fld.content_model_field.site_feature_value_tags(c,prefix,:full,:local => local)
          end
        end
      end

      if publication.form?
        define_form_fields_loop_tag("#{prefix}:field")
        define_value_tag("#{prefix}:field:label")
	expansion_tag("#{prefix}:field:required")
        define_value_tag("#{prefix}:field:control")
        define_value_tag("#{prefix}:field:error")
      end
    end
    
    def method_missing(method,*args) #:nodoc:
      method = method.to_s
      if method == 'define_tag'
        @method_list << [ 'tag', args[0] ]
      elsif method.to_s =~ /^define_((.*)_tag)$/
        @method_list << [ $1, args[0] ]
      elsif method.to_s =~  /^((.*)_tag)$/
        @method_list << [ $1, args[0] ]
      else
        nil
      end
    end

    
    
     # get versions of all the define_... methods without the define
    skip_methods = %w(define_form_tag define_tag)
    instance_methods.each do |method_name|
      if !skip_methods.include?(method_name) && method_name =~ /define\_(.*)/
        alias_method $1.to_sym, method_name.to_sym
      end
    end    
  end
  
  def self.available_features #:nodoc:
    []
  end
  
  def form_tag(url="", opts={})
    tag(:form, {:action => url, :method => 'post'}.merge(opts), true) + "<CMS:AUTHENTICITY_TOKEN/>"
  end

  # Is this feature currently displaying documentation or actually rendering the feature
  def documentation
    @display_documentation ? true : false
  end
  
  def set_documentation(val) #:nodoc:
   @display_documentation = val
  end

  # Run a feature where the tags need to be re-parsed each time
  # dummy file
  def webiva_custom_feature(feature_name,data={},&block)
    webiva_feature(feature_name,data,&block)
  end

  # Run a feature that can be cached 
  def webiva_feature(feature_name,data={})
  if !self.documentation
     parser_context = FeatureContext.new(self) do |c| 
      c.define_position_tags  
      c.define_domain_prefix_tag
      yield c
      
      # Get each of the handler option models
      # See if this feature has an extensions
      get_handler_info(:site_feature,feature_name).each do |handler|
          handler[:class].send("#{feature_name}_feature".to_sym,c,data)
      end      
      
     end 
     opts = {}
     opts[:site_feature_id] = data[:site_feature_id] if data.has_key?(:site_feature_id)
     opts[:custom_feature_body] = data[:custom_feature_body] if data.has_key?(:custom_feature_body)
     feature = get_feature(feature_name,opts)
     feature.body_html = single_feature(data[:partial_feature], feature.body_html) unless data[:partial_feature].blank?
     parse_feature(feature,parser_context)
  else
    documenter = FeatureDocumenter.new(self) do |c|
      yield c

      get_handler_info(:site_feature,feature_name).each do |handler|
          handler[:class].send("#{feature_name}_feature".to_sym,c,data)
      end
    end
    documenter.method_list.sort { |a,b| a[1] <=> b[1] }
  end
 end

  def single_feature(tag_name, feature_body)
    if feature_body =~ /(<cms:#{tag_name}.*?\/cms:#{tag_name}>)/m
      $1
    else
      feature_body
    end
  end

 def get_feature(type,options = {}) #:nodoc:
    if options.has_key?(:custom_feature_body)
      SiteFeature.new(:body_html => options[:custom_feature_body], :options => {})
    elsif options.has_key?(:site_feature_id) && @feature_override = SiteFeature.find_by_id(options[:site_feature_id])
      @feature_override
    elsif !options.has_key?(:site_feature_id) && @para.site_feature && (@para.site_feature.feature_type == :any || @para.site_feature.feature_type == type.to_s)
      @para.site_feature
    else
      if @para.content_publication
        SiteFeature.new(:body_html => @para.content_publication.default_feature, :options => {})
      else
        opts = self.class.send("get_feature_options_#{type}")
        require_css(opts[:default_css_file]) if !Configuration.options.skip_default_feature_css && opts[:default_css_file]
        SiteFeature.new(:body_html => self.class.send("get_default_feature_#{type}"), :options=> { :default => true } )
      end
    end
  end
  
  
  def parse_feature(feature,context) #:nodoc:
      options = feature.options || {}
        
      SiteTemplate.add_standard_parsing!(context,:values => options[:values],
                                                 :language => paragraph.language, 
                                                 :localize_values => options[:localize_values],
                                                 :localize => options[:localize],
                                                 :default_feature => options[:default] )

      context.header_tag('header')
      context.meta_tag('meta')

      feature_parser = Radius::Parser.new(context, :tag_prefix => 'cms')
      begin
        feature_parser.parse(feature.body_html || feature.body)
      rescue  Radius::MissingEndTagError => err
        if RAILS_ENV!='production' || myself.editor?
          "<div><b>#{'Feature Definition Contains an Error'.t}</b><br/>#{err.to_s.t}</div>"
        else
          ""
        end
      rescue Radius::UndefinedTagError => err
        if  RAILS_ENV!='production' || myself.editor?
          "<div><b>#{'Feature Definition Contains an Undefined tag:'.t}</b>#{err.to_s.t}</div>"
        else
          ""
        end
      end
  end
  
  
  def variable_replace(txt,vars = {}) #:nodoc:
    txt.gsub(/\%\%(\w+)\%\%/) do |mtch|
      var_name =$1.downcase.to_sym
      vars[var_name] ? vars[var_name] : ''
    end
  end
  
  # Return options for the named module
  def module_options(md) 
    cls = "#{md.to_s.camelcase}::AdminController".constantize
    cls.module_options
  end
  
  # Return a paragraphs ajax url for the current paragraph
   def ajax_url(options={})
     if @renderer.paragraph &&  @renderer.paragraph.page_revision
       opts = options.merge(:site_node => @renderer.paragraph.page_revision.revision_container_id, 
                            :page_revision => @renderer.paragraph.page_revision.id,
                            :paragraph => @renderer.paragraph.id)
       paragraph_action_url(opts)
     end
  end  
   
end
