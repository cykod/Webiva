# Copyright (C) 2009 Pascal Rettig.



class Blog::PageFeature < ParagraphFeature

  feature :blog_entry_list, :default_feature => <<-FEATURE
    <cms:entries>
      <cms:entry>
        <div class='blog_entry'>
          <cms:image align='left' border='10' size='preview' shadow='1' />
          <h3><a <cms:detail_href/>><cms:title/></a></h3>
          <cms:preview/>
          <cms:more><a <cms:detail_href/>>Read More...</a><br/><br/></cms:more>
          <div class='blog_info'>
             Posted <cms:published_at /> by <cms:author/> | <a <cms:detail_href/>>User Comments (<cms:comment_count/>)</a><br/><br/>
             <cms:categories> Categories: <cms:value/> <cms:tags> | </cms:tags> </cms:categories> 
             <cms:tags> Tags: <cms:value/> </cms:tags>
          </div>
        </div>
        <div style='clear:both;'></div>
        <cms:not_last><hr/></cms:not_last>
      </cms:entry>
    </cms:entries>
  FEATURE
  
  def blog_entry_list_feature(data)
    webiva_feature('blog_entry_list') do |c|
      
      c.define_value_tag 'title' do |tag|
        exists = !data[:type].blank? && !data[:identifier].blank?
        tag.locals.value = "Showing #{data[:type]} &gt; #{data[:identifier]}"
        tag.single? ? tag.locals.value : (exists ? tag.expand : nil)
      end
   
      c.define_tag 'entries' do |tag|
        data[:entries].length > 0 ? tag.expand : nil
      end
      c.define_tag 'no_entries' do |tag|
        data[:entries].length > 0 ? nil : tag.expand 
      end

      c.define_tag 'entry' do |tag|
        result = ''
        data[:entries].each do |entry|
          tag.locals.entry = entry
          tag.locals.first = entry == data[:entries].first
          tag.locals.last = entry == data[:entries].last
          result << tag.expand
        end

        result
      end

      define_position_tags(c)
      
      blog_entry_tags(c,data)

      c.define_pagelist_tag('pages') do |t|
         { :pages => data[:pages][:pages],:page => data[:pages][:page] }  
      end
    end
  end
   
   
   
  feature :blog_entry_detail, :default_feature => <<-FEATURE
      <cms:entry>
        <div class='blog_entry'>
          <cms:image align='left' border='10' size='preview' shadow='1' />
          <h3><cms:title/></h3>
          <cms:body/>
        </div>
          <cms:embedded_media>
            <div style='clear:both;'></div>
            <br/><br/>
            <div align='center'><cms:value/></div>
            <br/>
          </cms:embedded_media>
          <cms:media_file>
            <div style='clear:both;'></div>
            <br/><br/>
            <div style='text-align:center;'><cms:value/></div>
          </cms:media_file>
          <div class='blog_info'>
             Posted <cms:published_at /> by <cms:author/> <br/>
             <cms:categories>Categories: <cms:value/> <cms:tags>|</cms:tags> </cms:categories> 
             <cms:tags>Tags: <cms:value/></cms:tags>
          </div>
        <div style='clear:both;'></div>
      </cms:entry>
      <cms:no_entry>Invalid Post</cms:no_entry>
  FEATURE
  
  def blog_entry_tags(c,data)
      c.value_tag('blog_name') { |t| data[:blog].name }
      c.value_tag('blog_description') { |t| data[:blog].description } 
      c.value_tag('blog_target_id') { |t| data[:blog].target_id } 
      
  
      c.value_tag('entry:embedded_media') { |tag| tag.locals.entry.active_revision.embedded_media }
      
      c.define_tag 'entry:media_file' do |tag|
        med = tag.locals.entry.active_revision.media_file
        if med
          ext = med.extension.to_s.downcase
          
          case ext
          when 'mp3'
            width = (tag.attr['width'] || 320).to_i
           "<div id='blog_media_#{tag.locals.entry.id}'></div>
            <script>
              var so = new SWFObject('/javascripts/jw_player/mp3player.swf','mpl','#{width}','20','7');
              so.addVariable('file','#{med.url}');
              so.addVariable('autostart','false');
              so.write('blog_media_#{tag.locals.entry.id}');
            </script>"
          when 'flv'
           width = (tag.attr['width'] || 320).to_i
           height = (tag.attr['height'] || 260).to_i
           "<div id='blog_media_#{tag.locals.entry.id}'></div>
            <script>
              var so = new SWFObject('/javascripts/jw_player/mediaplayer.swf','mpl','#{width}','#{height}','7');
              so.addVariable('file','#{med.url}');
              so.addVariable('autostart','false');
              so.write('blog_media_#{tag.locals.entry.id}');
            </script>"
          when 'mov'
           width = (tag.attr['width'] || 320).to_i
           height = (tag.attr['height'] || 260).to_i
            "<embed src='#{med.url}' width='#{width}' height='#{height}' autoplay='false' />"
          else
            "<a href='#{med.url}'>Download Media</a>"
          end
        else
          nil
        end
      end
      
      c.date_tag('entry:published_at',"%H:%M%p on %B %d %Y".t) { |t|  t.locals.entry.published_at }
      c.image_tag('entry:image') { |t| t.locals.entry.image }
      c.expansion_tag('entry:comments') { |t| t.locals.entry.comments_count > 0 }
      c.value_tag('entry:comment_count') { |t| t.locals.entry.comments_count }
      
      
      %w(title author).each do |elem|
        c.value_tag('entry:' + elem) { |tag| h(tag.locals.entry.active_revision.send(elem)) }
      end
      
      c.value_tag('entry:body') { |tag| tag.locals.entry.active_revision.body_content }
      c.value_tag('entry:preview') {  |tag| tag.locals.entry.active_revision.preview_content }

      c.value_tag 'entry:preview_title' do |tag|
        h(tag.locals.entry.active_revision.preview_title.blank? ? tag.locals.entry.active_revision.title : tag.locals.entry.active_revision.preview_title)
      end

      c.expansion_tag('entry:more') { |tag| !tag.locals.entry.active_revision.preview.blank? }
      c.link_tag('entry:detail') { |tag|  "#{data[:detail_page]}/#{tag.locals.entry.permalink}" }
      c.link_tag('entry:full_detail') { |tag| "#{Configuration.domain_link(data[:detail_page].to_s + '/' + tag.locals.entry.permalink.to_s)}" }

      c.define_value_tag 'entry:categories' do |tag|
        categories = tag.locals.entry.blog_categories(true).collect(&:name)
        categories = categories[0..tag.attr['limit'].to_i] if tag.attr['limit']
        if categories.length > 0
          categories.map! { |cat| "<a href='#{data[:list_page]}/category/#{CGI::escape(cat)}'>#{h cat}</a>" } if tag.attr['no_link']
          categories.join(", ")
        else 
          nil
        end
      end

            
      c.define_value_tag 'entry:tags' do |tag|
        tags = tag.locals.entry.content_tags(true)
        if tags.length > 0
          tags.collect {|tg| "<a href='#{data[:list_page]}/tag/#{h tg.name}'>#{h tg.name}</a>" }.join(", ")
        else
          nil
        end
      end
  end

  def blog_entry_detail_feature(data)
    webiva_feature('blog_entry_detail') do |c|
      c.define_tag 'no_entry' do |tag|
        data[:entry] ? nil : tag.expand
      end
      c.define_tag 'entry' do |tag|
        tag.locals.entry = data[:entry]
        data[:entry] ? tag.expand : nil
      end
      
      blog_entry_tags(c,data)
   end
  end   
  
  
  
  feature :blog_categories, :default_feature => <<-FEATURE
<cms:categories>
  <cms:category>
    <a <cms:href/> <cms:selected>class='selected'</cms:selected>><cms:name/></a><br/>
  </cms:category>
</cms:categories>
<br/><br/>
<cms:recent_posts>
  <h4>Recent Posts</h4>
  <cms:post>
    <a <cms:href/>><cms:title/></a><br/>
  </cms:post>
</cms:recent_posts>
<br/><br/>
<cms:archives>
  <h4>Archives</h4>
  <cms:archive>
    <a <cms:href/>><cms:date format='%B %Y'/> (<cms:count/>)</a><br/>
  </cms:archive>
</cms:archives>
   FEATURE
   
  def blog_categories_feature(data)
   webiva_feature('blog_categories') do |c|
      c.define_expansion_tag('categories') { |tag| data[:categories].length > 0 }
      c.define_tag 'categories:category' do |tag|
        cats = data[:categories]
        if tag.attr['name']
          cat = cats.find() { |cat| cat.name == tag.attr['name'] }
          cats = cat ? [cat]  : []
        end
        c.each_local_value(cats,tag,'category')
      end   
      
      c.define_tag 'category:href' do |tag|
        "href='#{data[:list_url]}/category/#{CGI::escape(tag.locals.category.name)}'"
      end
      
      c.define_expansion_tag 'category:selected' do |tag|
        tag.locals.category.name == data[:selected_category].to_s
      end
      
      c.define_value_tag("category:name") { |tag| h(tag.locals.category.name) }
      
      c.define_expansion_tag 'recent_posts' do |tag|
        if !@recent_posts
          limit = (tag.attr['limit'] || 5).to_i
          @recent_posts =  Blog::BlogPost.find(:all,:include => [ :active_revision ], :order => 'published_at DESC',:conditions => ['blog_posts.status = "published" AND blog_posts.published_at < NOW() AND blog_blog_id=?',data[:blog_id]], :limit => limit)
        end
        
        @recent_posts.length > 0
      end 
      
      c.define_tag 'recent_posts:post' do |tag|
        c.each_local_value(@recent_posts,tag,'post')
      end
      
      c.define_tag 'recent_posts:post:href' do |tag|
        "href='#{data[:detail_url]}/#{tag.locals.post.permalink}'"
      end

      c.define_value_tag 'recent_posts:post:title' do |tag|
        h(tag.locals.post.active_revision.title)
      end
      
      c.define_expansion_tag 'archives' do |tag|
        if !@archives
          limit = (tag.attr['limit'] || 5).to_i
          @archives = Blog::BlogPost.find(:all,:select => "DATE_FORMAT(published_at,'%Y-%m') as date_grouping, COUNT(id) as cnt", :order => 'published_at DESC',:group => 'date_grouping',:conditions => ['blog_posts.status = "published" AND blog_posts.published_at < NOW() AND blog_blog_id=?',data[:blog_id]]).collect do |arch|
            dt = arch.date_grouping.split("-")
            { :date => Time.mktime(dt[0].to_i,dt[1].to_i),
              :cnt => arch.cnt }
          end
        end
        
        @archives.length > 0
      end
      
      c.define_tag "archives:archive" do |tag|
        c.each_local_value(@archives,tag,'archive')
      end
      
      c.define_value_tag "archives:archive:href" do |tag|
        formatted = tag.locals.archive[:date].strftime("%B%Y")
        "href='#{data[:list_url]}/archive/#{formatted}'"
      end
      
      c.define_value_tag "archives:archive:date" do |tag|
        format = tag.attr['format'] || '%B %Y'
        tag.locals.archive[:date].strftime(format)
      end
      
      c.define_value_tag "archives:archive:count" do |tag|
        tag.locals.archive[:cnt]
      end
        
      c.define_tag "href" do |tag|
        "href='#{data[:list_url]}'"
      end
    end
  end


  feature :blog_post_preview, :default_feature => <<-DEFAULT_FEATURE
<cms:entry>
<cms:img align='left' size='thumb'/><cms:preview/>
</cms>
DEFAULT_FEATURE

  def blog_post_preview_feature(data)
    webiva_renderer(:blog_post_preview) do |c|
       c.expansion_tag('entry') {  |t| t.locals.entry = data[:entry] }
       blog_entry_tags(c,data)
    end
  end

end


