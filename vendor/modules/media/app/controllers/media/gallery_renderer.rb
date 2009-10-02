# Copyright (C) 2009 Pascal Rettig.

class Media::GalleryRenderer < ParagraphRenderer
  include ActionView::Helpers::TextHelper
  
  feature :galleries, :default_data => { },  :default_feature => <<-FEATURE
    <cms:add_gallery>
<div align='right'>
<a <cms:href/>>Add Gallery</a>
</div>
</cms:add_gallery>
<div class='galleries'>
<table>

<cms:gallery>
<tr>
<td valign='top' align='center'>
<a <cms:overlay_href/> > <cms:thumb border='0' shadow='1' /> </a>
</td>
<td valign='top' style='padding-left:10px;' >
<div style='padding-top:4px;'>
<b><cms:name/></b><br/>
<cms:date format='%d.%m.%Y'><cms:value/><br/></cms:date>
<cms:description length='50'><cms:value/><br/></cms:description>
<cms:images/> <cms:trans>Photos</cms:trans> | <a <cms:href/> > <cms:trans>View Gallery</cms:trans> </a>
</div>

</td>
</tr>
<tr>
<td><img src='/images/spacer.gif' width='1' height='10'/></td>
</tr>
</cms:gallery>
</table>
</div>
<div class='galleries_pages'>
<cms:pages/>
</div>
  FEATURE
  
  def galleries_feature(feature,data)
    parser_context = FeatureContext.new do |c|
      c.define_tag 'gallery' do |tag|
        result = ''
        galleries = (data[:galleries] || [])
        c.each_local_value(galleries,tag,'gallery')
      end
      
      c.define_tag 'images' do |tag|
        tag.locals.gallery.gallery_images.length
      end
      
      
      c.define_tag 'gallery:name' do |tag|
        if tag.single?
          tag.locals.gallery.name
        elsif !tag.locals.gallery.name.to_s.empty?
          tag.locals.value = h tag.locals.gallery.name
          tag.expand
        else 
          nil
        end
      end
      
      
      c.define_tag 'gallery:description' do |tag|
        if tag.locals.gallery.description.to_s.empty?
          val = nil
        else
          val = truncate(h(tag.locals.gallery.description), tag.attr['length'].to_i || 40)
          tag.locals.value = val
        end
        
        tag.single? ? val : (val ? tag.expand : nil )
      end 
      
      c.define_date_tag('gallery:date') { |t| t.locals.gallery.occurred_at }
      c.define_date_tag('time',:format => "%T") { |t| t.locals.gallery.occurred_at }
      
      c.define_tag('value') { |t| t.locals.value }
      
      
      c.define_expansion_tag('add_gallery') { |t| myself.has_role?('gallery_create_galleries') }
      
      c.define_tag 'add_gallery:href'  do |tag|
        if data[:detail_page]
          "href='#{data[:detail_page]}/?edit=1'"
        else
          "href='javascript:void(0);'"
        end
        
      end
      
      c.define_tag 'href' do |tag|
        if data[:detail_page]
          "href='#{data[:detail_page]}/#{tag.locals.gallery.id}'"
        else
          "href='javascript:void(0);'"
        end
      end
      
      c.define_tag 'thumb' do |tag|
        img = tag.locals.gallery.gallery_images[0]
        
        attr = tag.attr.clone
        if img && img.domain_file
          icon_size = attr.delete('size') || 'thumb'
          size = %w(icon thumb preview small original).include?(icon_size) ?  icon_size : nil
          size = nil if size == 'original'
          img_size = img.domain_file.image_size(size)
          img_tag =  tag('img',attr.merge(:src => img.domain_file.url(size),:width => img_size[0],:height => img_size[1]))

          if attr.delete('shadow')
            "<div style='width:#{img_size[0] + 12}px' class='cms_gallery_shadow'><div><p>" + img_tag +
            "</p></div></div>"
          else
            img_tag
          end
        else
          img_tag = tag('img',attr.merge(:src => '/images/site/missing_thumb.gif'))
          if attr.delete('shadow')
            "<div style='width:#{64 + 12}px' class='cms_gallery_shadow'><div><p>" + img_tag +
            "</p></div></div>"
          else
            img_tag
          end
          
        end
      end
      
      c.define_tag 'icon' do |tag|
        img = tag.locals.gallery.gallery_images[0]
        if img && img.domain_file
          img.domain_file.url(:icon)
        else
          '/images/site/missing_icon.gif'
        end
      end
      
      c.define_tag 'overlay_href' do |tag|
        if tag.locals.gallery.gallery_images.size > 0
          "href='javascript:void(0);' onclick='CmsGallery.preloadOverlay(\"#{url_for :controller => "/media/gallery", :action => 'gallery_overlay', :path => [tag.locals.gallery.id]}\");'"
        elsif data[:detail_page]
          "href='#{data[:detail_page]}/#{tag.locals.gallery.id}'"
        else
          "href='javascript:void(0);'"
        end
          
      end
      
      define_pages_tag(c,data[:path],data[:page],data[:pages])
      
      c.define_position_tags
      
    end
        
    parser_context.globals.data = data
  
    parse_feature(feature,parser_context) 
    
  end
  
  # Galleries Paragraph Displays a list of galleries with certain conditions
  paragraph :galleries
  
  def self.galleries_hash(para,usr)
    nil
  end
  
  
  def galleries
      options = paragraph.data
      
      page_size = options[:images_per_page].to_i
      page_size = 10 if page_size <= 0
      
      pages = (Gallery.count.to_f / (page_size || 10)).ceil
      pages = 1 if pages < 1
      page = (params[:page] ? params[:page].to_i : 1).clamp(1,pages)
      
      offset = (page-1) * page_size
      
      
      conditions = nil
      if options[:display_type] != 'all' && options[:selected_galleries].is_a?(Array) && options[:selected_galleries].length > 0
        conditions = "galleries.id IN (" + options[:selected_galleries].collect { |gid| DomainModel.connection.quote(gid) }.join(",") + ") "
      end
      gallery_list= Gallery.find(:all,:order => 'occurred_at DESC',
                                               :offset => offset,
                                               :conditions => conditions,
                                               :limit => page_size)      
      
      detail_page = SiteNode.find_by_id(options[:detail_page]);

      data = { :galleries  => gallery_list,
               :detail_page => detail_page  ? detail_page.node_path : nil,
               :path => page_path,
               :page => page,
               :pages => pages }
      
      require_css('redbox')
      require_css('gallery')
      require_js('prototype')
      require_js('effects')
      require_js('builder')
      require_js('redbox')
      require_js('helper/gallery')
      
      render_paragraph :text => galleries_feature(get_feature('galleries'),data) 
  end
  
  
  feature :gallery, :default_data => { },  :default_feature => <<-FEATURE
    <cms:no_gallery>
      No Valid Gallery
    </cms:no_gallery>
   <cms:gallery>
    <h1><cms:name/></h1>
    <table width='100%'>
    <tr>
    <td></td>
    <cms:edit_gallery>
    <td nowrap='1' align='right'>
    <a <cms:href/>><cms:trans>Editer Gallerie</cms:trans></a>
    </td>
    </cms:edit_gallery>
    </tr>

    <tr>
    <td>
    <cms:date format="%A %d %B %Y" />
    </td>
    <cms:upload_image>
    <td nowrap='1' align='right'>
    <a <cms:href/>><cms:trans>Upload Image</cms:trans></a>
    </td>
    </cms:upload_image>
    </tr>
    <tr><td>
    <cms:description/>
    </td>
    </tr>
    </table>
    <br/>
    <table width='100%'>
    <tr>
    <cms:image>
    <td valign='bottom'>
    <a <cms:href/> > <cms:thumb size='preview' border='0' shadow='1'/></a>
    <cms:edit>
    <a <cms:href link='edit'/>><cms:add_text><cms:trans>No Description</cms:trans></cms:add_text><cms:edit_text><cms:name/></cms:edit_text></a> |
    <a <cms:href link='delete'/>>X</a>
    </cms:edit>
    <cms:no_edit>
    <cms:name/>
    </cms:no_edit>
    <br/><br/>
    </td>
    <cms:multiple value='3'>
    </tr><tr>
    </cms:multiple>
    
    </cms:image>
    </tr>
    </table>
    <div class='gallery_pages'>
    <cms:pages/>
    </div>
    </cms:gallery>
  FEATURE
  
  def gallery_feature(feature,data) 
     parser_context = FeatureContext.new do |c|

      c.define_expansion_tag('no_image') { |t| !data[:images] || data[:images].length == 0  }

      c.define_tag 'image' do |tag|
        result = ''
        images = (data[:images] || [])
        remove_images = []
        images.each_with_index do |image,idx|
            if image.domain_file
              tag.locals.image= image
              tag.locals.index = idx
              tag.locals.first = image== images.first
              tag.locals.last =  image== images.last
              result << tag.expand
            else
              image.destroy
            end
        end
        result
      end
      
      c.define_expansion_tag('gallery') {|t| data[:gallery] }

      c.define_value_tag('gallery:gallery_id') { |t| data[:gallery].id }
      c.define_value_tag('gallery:name') { |t| data[:gallery].name }
      c.define_value_tag('gallery:category') { |t| data[:gallery].category }
      c.define_value_tag('gallery:images') {|t|  data[:gallery].gallery_images.length.to_s }
      
      c.define_link_tag('gallery:overlay') do |t|
          { :href => 'javascript:void(0);',
            :onclick => "CmsGallery.overlayDisplay(#{data[:gallery].id},0); return false;" }
      end
      
      c.define_image_tag('gallery:thumb') { |tag| data[:gallery].gallery_images[0].domain_file }
      
      c.define_value_tag 'gallery:image:name' do |tag|
        name = tag.locals.image.name.to_s
        if name
          truncate(name,(tag.attr['length'] || 15).to_i)
        elsif  tag.attr['no_title']
          tag.attr['no_title']
        else 
          nil
        end
      end
      
      c.define_tag 'gallery:upload' do |tag|
        <<-FRM
        <form method='post' enctype='multipart/form-data'>
          #{"Add an Image".t}:
          <input id="gallery_upload_file_temp" name="gallery_upload[file_temp]" type="hidden" /><input id="gallery_upload_file" name="gallery_upload[file]" size="30" type="file" />
          <input type='submit' value='#{"Upload".t}' />
        </form>
        FRM
      end
      
      c.define_tag 'gallery:description' do |tag|
        data[:gallery].description
      end 
      
      c.define_tag 'gallery:date' do |tag|
      
        if data[:gallery].occurred_at 
          val = data[:gallery].occurred_at.localize(tag.attr['format'] || '%m/%d/%Y')
          tag.locals.value = val
        else
          val = nil
        end
        
          
        tag.single? ? val : ( val ? tag.expand : nil )        
      end
      
      c.define_tag 'gallery:date:value' do |tag|
        tag.locals.value
      end
      
      c.define_tag 'gallery:time' do |tag|
        if data[:gallery].occurred_at 
          data[:gallery].occurred_at.localize(tag.attr['format'] || '%T')
        else
          ''
        end
      end
      
      c.define_tag 'gallery:edit_gallery' do |tag|
        data[:can_edit] ?  tag.expand : ''
      end
      
      c.define_tag 'gallery:edit_gallery:href' do |tag|
        "href='#{page_path}?edit=1'"
      end
      
      c.define_tag 'gallery:upload_image' do |tag|

        (data[:can_upload]  ?  tag.expand : '')
      end
      
      c.define_tag 'gallery:upload_image:href' do |tag|
        "href='javascript:void(0);' onclick='CmsGallery.uploadImage(#{data[:gallery].id});'"
      end
      
      c.expansion_tag('gallery:edit') { |t| data[:can_edit] }
      
      c.define_tag 'gallery:image:edit:href' do |tag|
        if tag.attr['link'] == 'delete'
          "href='javascript:void(0);' onclick='CmsGallery.deleteImage(#{data[:gallery].id},#{tag.locals.image.id});'"
        else
          "href='javascript:void(0);' onclick='CmsGallery.editInfo(#{data[:gallery].id},#{tag.locals.index + data[:offset]});'"
        end
      end
      
      c.define_value_tag('gallery:image:caption') { |t| t.locals.image.name }
      
      c.define_tag 'gallery:image:add_text' do |tag|
        if tag.locals.image.name.to_s.empty? 
          tag.expand
        else
          ''
        end
      end
      

      c.expansion_tag('gallery:can_edit') { |t| data[:can_edit] }
      
      c.define_tag 'gallery:image:edit_text' do |tag|
        if tag.locals.image.name.to_s.empty?
          ''
        else
          tag.expand
        end
      end
      
      c.define_tag 'gallery:image:href' do |tag|
        img = tag.locals.image
        if img && img.domain_file
          url = img.domain_file.url
          size = img.domain_file.image_size
          <<-IMAGE
            href='#{url}' target='_blank' onclick='CmsGallery.overlayDisplay(#{data[:gallery].id},#{tag.locals.index + data[:offset]}); return false;'
        IMAGE
        else
          ''
        end        
      end
      
      c.define_image_tag('gallery:image:thumb',nil,nil,:size => :thumb) { |t| t.locals.image.domain_file  if t.locals.image}
      c.define_image_tag('gallery:image:icon',nil,nil,:size => :icon) { |t| img && img.domain_file ? tag.locals.gallery.gallery_images[0] : '/images/site/missing_icon.gif' }
      define_pages_tag(c,data[:page_path],data[:page],data[:pages])
      define_position_tags(c)
   end
   
   parse_feature(feature,parser_context) 

  end
  
  # Gallery Paragraph Display a specific gallery, based on the Gallery Number input connection
  paragraph :gallery, :default_connection => :gallery_id
  
  def gallery
    options = paragraph.data
    gallery_options = paragraph_options(:gallery)
    
    if options[:gallery_id].to_i > 0
      current_gallery = Gallery.find_by_id(options[:gallery_id])
    elsif editor?
      current_gallery = Gallery.find(:first)
    else
      gallery_connection,gallery_id = page_connection()
      target_name = gallery_id.name if gallery_id.respond_to?(:name)
      
      if gallery_connection == :container
        if gallery_id
          if !options[:gallery_category].blank?
            current_gallery = Gallery.find(:first,:conditions => ['container_type=? AND container_id=? AND category=?',gallery_id.class.to_s,gallery_id.id,options[:gallery_category]])
          else
            current_gallery = Gallery.find(:first,:conditions => ['container_type=? AND container_id=?',gallery_id.class.to_s,gallery_id.id])
          end
          current_gallery = Gallery.create(:container => gallery_id,:category => options[:gallery_category],:name => "#{target_name} #{options[:gallery_category]}") if !current_gallery && options[:gallery_create]
        end
      else
        current_gallery = Gallery.find_by_id(gallery_id)
      end
    end
    
    
    # run page edit information if edit parameter & have 
    if params[:edit]
      if ((current_gallery && myself.has_role?('gallery_edit_galleries')) || (!current_gallery && myself.has_role?('gallery_create_galleries')))
        unless current_gallery
          current_gallery = Gallery.new
        end
        edit_gallery(current_gallery)
        return 
      end
    end
    
    
    if current_gallery 
      note = ''
      
      page_size = options[:images_per_page].to_i
      page_size = 10 if page_size <= 0
      
      pages = (current_gallery.gallery_images.size.to_f / (page_size || 10)).ceil
      pages = 1 if pages < 1
      page = (params[:page] ? params[:page].to_i : 1).clamp(1,pages)
      offset = (page-1) * page_size
      
      can_edit = myself.user_profile.has_role?('gallery_upload_to_galleries') 
      if !can_edit && current_gallery.container
        if  current_gallery.container.respond_to?(:gallery_can_edit)
          can_edit =  current_gallery.container.gallery_can_edit(myself)
        end
      end
      can_upload = can_edit


      if !can_upload &&  current_gallery.container
        if  current_gallery.container.respond_to?(:gallery_can_upload)
          can_upload =  current_gallery.container.gallery_can_upload(myself)
        end
      end


      
      if request.post?
        if params[:gallery_upload]
          if can_upload
            unless current_gallery.domain_file_id
              gallery_folder_id = Configuration.options[:gallery_folder] || 1
              folder = DomainFile.create_folder(current_gallery.name,gallery_folder_id,:automatic => true,:special=>'gallery')
              current_gallery.update_attribute(:domain_file_id,folder.id)
            end
            
            domain_file = DomainFile.image_upload(params[:gallery_upload][:file],current_gallery.domain_file_id)
            if domain_file
              gi = current_gallery.gallery_images.find_by_domain_file_id(domain_file.id)
              gi.update_attributes(:name => params[:gallery_upload][:description],:approved => 1) if gi
              
              current_gallery.resort_images(gallery_options.autosort == 'asc' ? true : false ) if gallery_options.autosort != 'no'
              
              redirect_paragraph page_path + "?page=#{pages+1}"
              return
            end
          end
        elsif params[:image]
          if can_edit
            img = current_gallery.gallery_images.find_by_id(params[:image][:image_id])
            img.update_attributes(:name => params[:image][:description])
            if params[:image][:position] && params[:image][:position].to_i != img.position
              img.insert_at(params[:image][:position])
            end

            current_gallery.resort_images(gallery_options.autosort == 'asc' ? true : false )  if gallery_options.autosort != 'no'
            
            redirect_paragraph page_path + "?page=#{page}"
            return
          end
        elsif params[:delete_image] && params[:delete_image][:gallery_id].to_i == current_gallery.id
          if can_edit
            img = current_gallery.gallery_images.find_by_id(params[:delete_image][:image_id])
            img.domain_file.destroy if img.domain_file && img
            img.destroy if img

            current_gallery.resort_images(gallery_options.autosort == 'asc' ? true : false )  if gallery_options.autosort != 'no'
            
            redirect_paragraph page_path + "?page=#{page}"
            return
          end
        end
      end
      
      
      images = current_gallery.gallery_images.find(:all,:order => 'position',
                                                :offset => offset,
                                                :limit => page_size,
                                                :include => :domain_file)
    
    
      data = { :gallery => current_gallery,
              :images => images,
              :page => page,
              :pages => pages,
              :offset => offset,
              :page_path => page_path,
              :can_upload => can_upload,
              :can_edit => can_edit
              }
      feature_output = gallery_feature(get_feature('gallery'),data) 
      
            

      
      require_css('redbox')
      require_css('gallery')
  
      require_js('prototype')
      require_js('effects')
      require_js('builder')
      require_js('redbox')
      require_js('helper/gallery')

      render_paragraph :partial => "/media/gallery/gallery_paragraph", 
                    :locals => { :feature_output => feature_output, 
                                  :can_upload => can_upload, 
                                  :can_edit => can_edit,
                                  :images => current_gallery ? current_gallery.gallery_images.find(:all,:order => 'position',:include => :domain_file) : [],
                                  :gallery => current_gallery,
                                  :page => page,
                                  :editing => self.editor?,
                                  :options => gallery_options }
    else
      data = {  }
      render_paragraph :text => gallery_feature(get_feature('gallery'),data) 
    end
    
  end
  
  def self.gallery_hash(para,usr,params = {})
    nil
  end
  
  # Private Gallery Display a private gallery (editiable by the owner), based on the Gallery Number input connection
  paragraph :private_gallery, :paragraph_cache => :gallery_hash, :input_connections =>[ [ 'Gallery Number','gallery_id'] ]
  
  
  def edit_gallery(current_gallery)
    options = paragraph.data

    new_gallery = current_gallery.id ? false : true
    
    if request.post? && params[:gallery]
      
      if current_gallery.update_attributes(params[:gallery])
        # If we have view page to go to,
        # Go there, otherwise just display the save page
          if new_gallery
            unless current_gallery.domain_file_id
              gallery_folder_id = Configuration.options[:gallery_folder] || 1
              folder = DomainFile.create_folder(current_gallery.name,gallery_folder_id,:automatic => true)
              current_gallery.update_attribute(:domain_file_id,folder.id)
            end
            redirect_paragraph page_path + "/" + current_gallery.id.to_s
          else
            redirect_paragraph page_path
          end
          return
      end
    elsif request.post? && params[:delete]
      if current_gallery.id == params[:delete].to_i
        current_gallery.destroy
        options = paragraph.data || {}
        if options[:list_page].to_i > 0
          list_page = SiteNode.find_by_id(options[:list_page].to_i)
          if list_page
            redirect_paragraph list_page.node_path
            return
          end
        end
        render_paragraph :text => 'Deleted Gallery'
        return
      end
    end
  
    require_js('prototype')
    require_js('user_application')
  
    render_paragraph :partial => "/media/gallery/edit_gallery", :locals => { :gallery => current_gallery, :saved_gallery => @saved } 
  end

end
