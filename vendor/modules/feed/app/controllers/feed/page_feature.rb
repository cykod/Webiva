class Feed::PageFeature < ParagraphFeature


  feature :feed_page_show, :default_feature => <<-FEATURE
    Please click toggle available tags to see the tags available in this feed
  FEATURE
  

  def feed_page_show_feature(data)
    webiva_custom_feature(:feed_page_show,data) do |c|
      c.expansion_tag('feed') {  |t| t.locals.feed = data[:output] }
      tag_generator_helper(c,nil,'feed',data[:output])
    end
  end

  def tag_generator_helper(c,name_base,local,object)
    if object.is_a?(Hash)
      name_base_blank = name_base
      name_base = name_base ? name_base + ":" : ''

      
      object.each do |key,value|
        key_tag = generate_tag_name(key)
        if value.is_a?(Hash)
          local_expansion_tag(c,name_base + key_tag,key,local)
          tag_generator_helper(c,name_base + key_tag,key,object[key])
        elsif value.is_a?(Array)
          loop_tag_name = key_tag.to_s.singularize
          plural_tag_name = loop_tag_name.to_s.pluralize
          c.loop_tag(name_base + loop_tag_name,plural_tag_name) { |t| t.locals.send(local)[key]  }
          tag_generator_helper(c,name_base + loop_tag_name,loop_tag_name,value[0])
        else
          value_tag_helper(c,name_base + key_tag,name_base_blank,key,local)
        end
      end
    end
  end

  def generate_tag_name(key)
    key.gsub(/ +|_+/,"_").gsub(/[^a-z0-9A-Z\_]/,'')
  end

  def local_expansion_tag(c,tag_name,key,local)
    c.expansion_tag(tag_name) do |t|
      obj = t.locals.send(local)
      t.locals.send("#{key}=",obj[key]) if obj
    end
  end

  def value_tag_helper(c,tag_name,name_base_blank,key,local)
    if key =~ /^.*\_at$/
     c.date_tag(tag_name,DEFAULT_DATETIME_FORMAT.t) { |t| obj = t.locals.send(local); obj[key] if obj }
    elsif key =~ /^.*\_on$/
     c.date_tag(tag_name,DEFAULT_DATE_FORMAT.t) { |t|  obj = t.locals.send(local); obj[key] if obj }
    elsif key =~ /^(.*)\_url$/
     c.link_tag(name_base_blank + ":" +  $1) {  |t| obj = t.locals.send(local); obj[key] if obj }
    elsif key =~ /^.*\url$/
     c.link_tag(name_base_blank) {  |t| obj = t.locals.send(local); obj[key] if obj }
    else
      c.value_tag(tag_name) { |t|  obj = t.locals.send(local); obj[key] if obj }
    end
  end
end
