
class Media::GalleryFeature < ParagraphFeature
  
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
  
  def galleries_feature(data)
    webiva_feature('galleries') do |c|
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
      
      
      c.define_expansion_tag('add_gallery') { |t| data[:can_edit]  }
      
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

      c.h_tag 'target' do |t|
        if t.locals.gallery.container && t.locals.gallery.container.respond_to?(:name)
          t.locals.gallery.container.name
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
      
      c.pagelist_tag('pages') { |t| data[:pages] }
    end
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
  
  def gallery_feature(data) 
     webiva_feature("gallery") do |c|
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
      c.define_h_tag('gallery:name') { |t| data[:gallery].name }
      c.define_h_tag('gallery:category') { |t| data[:gallery].category }
      c.define_value_tag('gallery:images') {|t|  data[:gallery].gallery_images.length.to_s }
      
      c.define_link_tag('gallery:overlay') do |t|
          { :href => 'javascript:void(0);',
            :onclick => "CmsGallery.overlayDisplay(#{data[:gallery].id},0); return false;" }
      end
      
      c.define_image_tag('gallery:thumb') { |tag| data[:gallery].gallery_images[0].domain_file }
      
      c.define_h_tag 'gallery:image:name' do |tag|
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
      
      c.h_tag 'gallery:description' do |tag|
        data[:gallery].description
      end 
      
      c.date_tag('gallery:date') { |t| data[:gallery].occurred_at }
      
      c.datetime_tag('gallery:time','%T'){ |t|  data[:gallery].occurred_at }
      
      c.expansion_tag('gallery:edit_gallery') { |t| data[:can_edit] }
      c.define_link_tag('gallery:edit_gallery:') { "#{page_path}?edit=1" }
      
      c.expansion_tag('gallery:upload_image') { |t| data[:can_upload] }
      
      c.define_tag 'gallery:upload_image:href' do |tag|
        "href='javascript:void(0);' onclick='CmsGallery.uploadImage(#{data[:gallery].id});'"
      end
      
      c.define_tag 'gallery:image:edit:href' do |tag|
        if tag.attr['link'] == 'delete'
          "href='javascript:void(0);' onclick='CmsGallery.deleteImage(#{data[:gallery].id},#{tag.locals.image.id});'"
        else
          "href='javascript:void(0);' onclick='CmsGallery.editInfo(#{data[:gallery].id},#{tag.locals.index + (data[:pages][:page] - 1) * data[:pages][:per_page]});'"
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
       
      c.define_link_tag 'gallery:image:' do |t|
        img = t.locals.image
        if img && img.domain_file
          url = img.domain_file.url(t.attr['size'])
        else
          nil
        end
      end

      c.define_tag 'gallery:image:overlay' do |tag|
        img = tag.locals.image
        if img && img.domain_file
          url = img.domain_file.url
          size = img.domain_file.image_size
          <<-IMAGE
            href='#{url}' target='_blank' onclick='CmsGallery.overlayDisplay(#{data[:gallery].id},#{tag.locals.index + (data[:pages][:page] - 1) * data[:pages][:per_page]}); return false;'
        IMAGE
        else
          ''
        end        
      end
      
      c.expansion_tag('gallery:image:edit') { |t| data[:can_edit] }
      c.define_image_tag('gallery:image:thumb',nil,nil,:size => :thumb) { |t| t.locals.image.domain_file  if t.locals.image}
      c.define_image_tag('gallery:image:icon',nil,nil,:size => :icon) { |t| img = t.locals.image;   img && img.domain_file ? t.locals.gallery.gallery_images[0] : '/images/site/missing_icon.gif' }

      c.pagelist_tag('pages') { |t| data[:pages] }
   end
  end



end
