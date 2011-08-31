
# Custom higher level form elements specific to Webiva
# included in cms_form_for and unstyled_cms_form_for
module WebivaFormElements

  include ActionView::Helpers::UrlHelper
  include PageHelper
  
  # Displays a File manager selection widget (admin only)
  # that lets a user select an image from the file manager
  def filemanager_image(field,options = {})
    fileId = @object.send(field)
    file = DomainFile.find_by_id(fileId) if fileId
    url = '/website/file/popup'
    url += "?field=#{@object_name}_#{field}"
    url += "&select=img"
    
    if file
      name = file.file_path
      thumb = file.url(:icon)
    else
      name = 'Select Image'.t
      thumb = "/images/spacer.gif"
    end
    <<-SRC
    <table><td valign='middle' align='center' style='width:32px;height:32px;border:1px solid #000000;'><img id='#{@object_name}_#{field}_thumb' src='#{thumb}' onclick='openWindow("#{url}" + "&file_id=" + $("#{@object_name}_#{field}").value,"selectFile",800,400,"yes","yes")'/></td><td valign='center' align='left'><a href='javascript:void(0);' onclick='openWindow("#{url}" + "&file_id=" + $("#{@object_name}_#{field}").value,"selectFile",1000,500,"yes","yes")'>

			<span id='#{@object_name}_#{field}_name' >#{name}</span>
			</a>
	<input type='hidden' name='#{@object_name}[#{field}]' id='#{@object_name}_#{field}' value='#{file.id if file}' />
	</td></tr></table>
		SRC
  end
  
  # Displays a File manager selection widget (admin only)
  # that lets a user select any type of file from the file manager
  def filemanager_file(field,options = {})
    if @object
      fileId = @object.send(field)
      file = DomainFile.find_by_id(fileId) if fileId
    end
    url = '/website/file/popup'
    url_options = "?field=#{@object_name}_#{field}"
    url_options += "&select=" + ( options[:type] || 'doc' ).to_s
    
    onchange = options.delete(:onchange)
    if onchange
      onchange = "onchange='#{onchange}'"
    else
      onchange = ''
    end
    if file
      name = file.file_path
    else
      name = 'Select File'.t
    end
    <<-SRC
      <a href='javascript:void(0);' onclick='openWindow("#{url}/" + $("#{@object_name}_#{field}").value + "#{url_options}" ,"selectFile",1000,500,"yes","yes")'>
      <span id='#{@object_name}_#{field}_name' >#{name}</span>
      </a>
      <input type='hidden' name='#{@object_name}[#{field}]' id='#{@object_name}_#{field}' value='#{file.id if file}' #{onchange} />
    SRC
  end
  
  # Shows a content selector that lets the user select a single item from 
  # specific content class
  def content_selector(field,content_class,options = {})
    if @object
      content_id =@object.send(field)
    end
    
    content = content_class.find_by_id(content_id) if content_id
    url = '/website/selector/popup'
    url_options = "?class_name=#{content_class.to_s.underscore}&field=#{@object_name}_#{field}"
    url_options += "&content_id=#{content.id}" if content
    callback = options.delete(:callback)
    url_options += "&callback=#{CGI.escape(callback)}" if callback
    if content 
      name = content.name
    else
      name = ("Select " + (options.delete(:content_name) || content_class.to_s.humanize)).t
    end
    url_options += "&name=#{CGI.escape(name)}"
    
    <<-SRC
     <a href='javascript:void(0);' onclick='openWindow("#{url}/" + $("#{@object_name}_#{field}").value + "#{url_options}" ,"selectFile",400,260,"yes","yes")'>
      <span id='#{@object_name}_#{field}_name' >#{name}</span>
      </a>
      <input type='hidden' name='#{@object_name}[#{field}]' id='#{@object_name}_#{field}' value='#{content.id if content}' />
     SRC
  end
  
  # Shows a content selector that lets the user select a multiple items from 
  # specific content class
  def multi_content_selector(field,content_class,options = {})
    if @object
      content_ids =@object.send(field)
    end
    
    content_objects = content_class.find(:all,:conditions => { :id => content_ids }) if content_ids
    url = '/website/selector/popup_multi'
    url_options = "class_name=#{content_class.to_s.underscore}&field=#{@object_name}_#{field}&field_name=#{@object_name}[#{field}]"
    callback = options.delete(:callback)
    url_options += "&callback=#{CGI.escape(callback)}" if callback
    if content_objects && content_objects.length > 0
      name = content_objects.map(&:name).join("<br/>")
      hidden_field_tags =  content_objects.map { |elm| "<input type='hidden' name='#{@object_name}[#{field}][]' value='#{elm.id}' />" }
    else
      name = ("Select " + (options.delete(:content_name) || content_class.to_s.humanize.pluralize)).t
    end
    url_options += "&name=#{CGI.escape(name)}"
    
    <<-SRC
     <a href='javascript:void(0);' onclick='openWindow("#{url}?content_ids=" + $$("##{@object_name}_#{field}_values input").map(function(elm) { return elm.value; }).join(",") + "&#{url_options}" ,"selectFile",400,260,"yes","yes")'>
      <span id='#{@object_name}_#{field}_name' >#{name}</span>
      </a>
      <div id='#{@object_name}_#{field}_values'>#{hidden_field_tags}</div>
     SRC
  end  
  
  # Displays a File manager selection widget (admin only)
  # that lets a user select a folder from the file manager
  def filemanager_folder(field,options = {})
    if @object
      fileId = @object.send(field)
    end
    file = DomainFile.find_by_id(fileId) if fileId
    url = '/website/file/popup'
    url_options = "?field=#{@object_name}_#{field}"
    url_options += "&select=fld"
    if file 
      name = file.file_path
    else
      name = 'Select Folder'.t
    end
    
    <<-SRC
      <a href='javascript:void(0);' onclick='openWindow("#{url}/" + $("#{@object_name}_#{field}").value + "#{url_options}" ,"selectFile",1000,500,"yes","yes")'>
      <span id='#{@object_name}_#{field}_name' >#{name}</span>
      </a>
      <input type='hidden' name='#{@object_name}[#{field}]' id='#{@object_name}_#{field}' value='#{file.id if file}' />
    SRC
  end
	
  # Color selection widget
  def color_field(field,options = {}) 
    color = @object.send(field)
    color ||= ''
    
    <<-SRC
      #{tag('input',options.merge(:name => "#{@object_name}[#{field}]", :id => "#{@object_name}_#{field}", :value => color, :size => 15, :onchange => "SCMS.updateColorField('#{@object_name}_#{field}');"  ) )}
      <a href='javascript:void(0);'
        onclick='if(!$("#{@object_name}_#{field}").disabled) SCMS.pickerWindow("/javascripts/pickers/color.htm",{cur_color:"#{color}",callback:"#{@object_name.to_s+'_'+field.to_s}"}, {width: 250, height: 150 })' id='#{@object_name}_#{field}_color' style='border:1px solid #000000; 
        #{"background-color:#{color};" unless color=='' }'>
        <img src='/images/spacer.gif' width='16' height='16' />
        </a>
    SRC
  end
  
  # Popup-calendar date selector
  def date_field(field,options = {})
    date_value = @object.send(field) if @object
    if date_value.is_a?(String)
      date_txt = date_value
    elsif date_value || !options.delete(:blank)
      date_txt = (date_value || Time.now).localize(Configuration.date_format)
    else
      date_txt = ''
    end
    url = '/website/public/calendar' 
    <<-SRC
      #{tag('input',options.merge(:name => "#{@object_name}[#{field}]", :id => "#{@object_name}_#{field}",:class => "date_field", :value => date_txt, :size => 15 ) )}
      <a href='javascript:void(0);'
        onclick='if(!$("#{@object_name}_#{field}").disabled) SCMS.pickerWindow("#{url}",{date: $("#{@object_name}_#{field}").value, callback:"#{@object_name.to_s+'_'+field.to_s}"}, {width: 250, height: 180 })' id='#{@object_name}_#{field}_date'>
        <img src='/images/calendar.gif' width='16' height='16' align='absmiddle' border='0'/>
        </a>
    
    SRC
  
  end

  # Popup-calendar date and time selector
  def datetime_field(field,options = {})
  
    date_value = @object.send(field) if @object
    if date_value.is_a?(String)
      date_txt = date_value
    elsif date_value || !options.delete(:blank)
      date_txt = (date_value || Time.now).localize(Configuration.datetime_format)
    else
      date_txt = ''
    end
    
    url = '/website/public/calendar' 
    <<-SRC
      #{tag('input',options.merge(:name => "#{@object_name}[#{field}]", :id => "#{@object_name}_#{field}", :value => date_txt ) )}
      <a href='javascript:void(0);'
        onclick='if(!$("#{@object_name}_#{field}").disabled) SCMS.pickerWindow("#{url}",{date: $("#{@object_name}_#{field}").value, show_time:true,  callback:"#{@object_name.to_s+'_'+field.to_s}"}, {width: 250, height: 200 })' id='#{@object_name}_#{field}_date'>
        <img src='/images/calendar.gif' width='16' height='16' align='absmiddle' border='0' />
        </a>
    
    SRC
  end
  
  # Displays a tinymce editor area
  def editor_area(field,options = {})
    txt = @object.send(field)
    
    options = options.clone
    tpl = options.delete(:template)
    filter = options.delete(:content_filter) || 'full_html'

    return self.send(:text_area,field,options) unless filter == 'full_html'

    options[:class] = 'cmsFormMceEditor'
    options[:style] = 'width:100%;' unless options[:style]

    txtarea = self.send(:text_area,field,options)
    
    elem_id = "#{@object_name}_#{field}"
    
    if tpl
      @content_css = "/stylesheet/#{tpl}.css"
      @design_styles = SiteTemplate.css_design_styles(tpl,'en')
    end
    if options[:inline]
    js = <<-EOF
      <script>
        if(!mceDefaultOptions) {
          var mceDefaultOptions = {
          theme : "advanced",
          theme_advanced_layout_manager: "SimpleLayout",
          auto_reset_designmode : true,
          mode : "none",
          valid_elements: "*[*]",
          plugins: 'table,filemanager,advimage,advlink,flash,paste',
          extend_valid_elements: 'a[name|href|target|title|onclick]',
          theme_advanced_buttons1 : "bold,italic,underline,separator,strikethrough,justifyleft,justifycenter,justifyright,justifyfull,bullist,numlist,outdent,indent,undo,redo,pastetext,pasteword,anchor,link,unlink,image,filemanager,hr",
          theme_advanced_buttons2 : "forecolor,backcolor,formatselect,fontselect,fontsizeselect,styleselect",
          theme_advanced_blockformats: "p,div,h1,h2,h3,h4,h5,h6,blockquote,dt,dd,code,samp",
          theme_advanced_buttons3 : "flash,tablecontrols,code",
          theme_advanced_toolbar_location : "top",
          theme_advanced_toolbar_align: 'left',
          external_link_list_url: "/website/edit/links",
          debug : false,
          relative_urls : false,
      	  remove_script_host : true,
      	  body_class : 'monthly_tip',
          image_insert_url: "/website/file/manage",
          
          theme_advanced_styles : "#{@design_styles.collect { |style| "#{style.humanize.capitalize}=#{style}" }.join(";")}", 
          external_link_list_url: "/website/edit/links",
          theme_advanced_toolbar_align: 'left',
          #{ "content_css: '#{@content_css}'" if @content_css },
          debug : false,
          relative_urls : false,
      	  remove_script_host : true,          
          

       };
             
      try {
        if(cmsEditorOptions) {
          mceDefaultOptions = Object.extend(mceDefaultOptions,cmsEditorOptions)
        }
      }
      catch(err) {  }
      tinyMCE.init(mceDefaultOptions);    
      }
      Event.observe( window, 'load',function() { tinyMCE.execCommand('mceAddControl',true,'#{elem_id}'); } );
      </script>
    EOF
    txtarea += js
    end
    txtarea
  end

  # Front end image upload field  
  def upload_image(field,options = {})
    image_file_id =  @object.send(field)
    image_file = DomainFile.find_by_id(image_file_id)
    no_label = options[:no_label]
    current_image= nil
    if image_file && !image_file.url.to_s.empty?
      current_image = <<-IMAGE_SOURCE
      <a href='javascript:void(0);' onclick='document.getElementById("#{@object_name}_#{field}_clear").value="0"; this.innerHTML = "";'  style='display:block;width:66px;height:66px;text-align:center;border:1px solid #CCCCCC;padding:0px;margin;0px;'>
      <img src='#{image_file.url(:thumb)}' style='padding:0px;margin:0px;border:0px;' title='Click to remove image' />
      </a>
    IMAGE_SOURCE
   end
    <<-SRC
      <table cellpadding='0' cellspacing='0'><tr><td>
      #{current_image}</td><td>
      #{("Upload Image".t + ":<br/>") unless no_label }
      <input type='hidden' name='#{@object_name}[#{field}_clear]' id='#{@object_name}_#{field}_clear' value='#{image_file ? image_file.id : ''}' />
      <input type='file' name='#{@object_name}[#{field}]' id='#{@object_name}_#{field}' />
      </td></tr></table>
    SRC
  
  end
  
  # Front end file upload field  
  def upload_document(field,options = {})
    doc_file_id =  @object.send(field)
    doc_file = DomainFile.find_by_id(doc_file_id)
    maxlength = options.delete(:maxlength)
    maxlength = "maxlength='#{maxlength}'" if maxlength
    current_doc= nil
    if doc_file && !doc_file.url.to_s.empty?
      current_doc = <<-DOC_SOURCE
      <input type='hidden' name='#{@object_name}[#{field}_clear]' id='#{@object_name}_#{field}_clear' value='#{doc_file ? doc_file.id : ''}' />
      <span id="#{@object_name}_#{field}_file">
      <a href='#{doc_file.url}' target='_blank' >
      <img src='/images/site/document.gif' style='width:16px;height:16px;padding:0px;margin:0px;border:0px;' />
      #{h doc_file.name}
      </a>&nbsp;
      <a href='javascript:void(0);' onclick='document.getElementById("#{@object_name}_#{field}_clear").value="0"; document.getElementById("#{@object_name}_#{field}_file").innerHTML="";'>#{"(Remove)".t}</a>
      </span><br/>
    DOC_SOURCE
   end
    <<-SRC
      #{current_doc}
      <input type='file' name='#{@object_name}[#{field}]' id='#{@object_name}_#{field}' #{maxlength}/>
    SRC
  
  end



  # unsorted Multi-select (deprecated)
  def unsorted_selector(field,available_values,selected_values,options = {})

    <<-SRC
    <script type='text/javascript'>
      var #{field.to_s}_editor  = {
        options: new Array(  #{available_values.collect { |elem| "[\"#{elem[0]}\",\"#{elem[1]}\"]" }.join(",") } ),

        updateSelectors: function() {

          var values = $("#{@object_name}_#{field}").value.split("|");
          $("#{@object_name}_#{field.to_s}_available_options").options.length = 0;
          
          var selectedValues = [];

          for(var i=0,len = this.options.length;i < len;i++) {
              var opt = this.options[i];
              if(opt[1] == '' || values.indexOf(opt[1]) == -1) {
                $("#{@object_name}_#{field.to_s}_available_options").options.add(new Option(this.options[i][0],this.options[i][1]));
              }
              else if(opt[1] != '') {
                  selectedValues.push(opt);
              }
          }
          var displayElem = $('#{@object_name}_#{field}_display');
          displayElem.innerHTML = '';
          for(var k=0,len = selectedValues.length;k<len;k++) {
            displayElem.innerHTML += "<a href='javascript:void(0);' onclick='#{field.to_s}_editor.removeElement(\\"" + selectedValues[k][1] + "\\");'>" + selectedValues[k][0] + "</a><br/>";
          }
        },
        addElement: function() {
            var values = $("#{@object_name}_#{field}").value.split("|");
            var selected = $("#{@object_name}_#{field.to_s}_available_options").value;
            if(selected == '')
              return;
            values.push(selected);
            $("#{@object_name}_#{field}").value = values.uniq().join("|");
            this.updateSelectors();
        },
        removeElement: function(value) {
            var values = $("#{@object_name}_#{field}").value.split("|");
            values = values.without(value,'');
            $("#{@object_name}_#{field}").value = values.uniq().join("|");
            this.updateSelectors();
        }
      }
    </script>
    <input type='hidden' name='#{@object_name}[#{field}]' id='#{@object_name}_#{field}' value="#{selected_values.collect { |elem| elem[1] }.join("|")}" />
    <select name='#{@object_name}_#{field.to_s}_available_options' id='#{@object_name}_#{field.to_s}_available_options'></select>
    <button onclick='#{field.to_s}_editor.addElement(); return false;'>Add</button><br/>
    <div size='#{options[:size]||5}' id='#{@object_name}_#{field}_display' style='border:1px solid; height:6em; overflow:auto;'>
    </div>
    <script type='text/javascript'>#{field.to_s}_editor.updateSelectors();</script>

    SRC
  end
 
 
      
  def price_range(field, prices, opts = {}) #:nodoc:
  
    object_name = @object_name
    field_values = @object.send(field)
    price_values = @object.send(prices)
    field_name = field.to_s
    price_name = prices.to_s
    options = { :field => field.to_s, 
                :field_units => opts[:field_units],
                :measure => opts[:measure] || 'units', 
                :units => opts[:units] || 'lbs', 
                :currency => opts[:currency] || ['$',''] 
              }
    
    <<-SRC
    <script type='text/javascript'>
     #{object_name}_#{field_name}_editor = {
          
      changedUnit: function(elem) {
        if(elem.value != '' && !(Number(elem.value) > 0.0)) {
          alert('#{"Please enter a valid %s" / options[:measure]}');
          elem.select();
          setTimeout(function() {elem.focus(); },10);
          return;
        }
        else {
          if(elem.value != '')
            elem.value = Number(elem.value).toFixed(#{options[:field_units] || 1});
          this.updateUnits();
        
        }
      },
      
      changedPrice: function(elem) {
        elem.value = Number(elem.value).toFixed(2);
      
      },
      
      updateUnits: function() {
        var i=0;
        var units = [];
        while($('#{object_name}_#{field_name}_' + i)) {
          units.push({ unit: $('#{object_name}_#{field_name}_' + i).value,
                         price: $('#{object_name}_#{price_name}_' + i).value })
        
          i++;
        }
        units.sort(function(a,b) {
            if(b['unit'] == '') return -10;
            if(a['unit'] == '') return 10;
            return a['unit'] - b['unit'];
          });

        if(units.length == 0 || units[units.length - 1]['unit'] != '') {
          units.push( { unit: '', price: '' } );
        }

        // Find the last non-blank one
        for(var k = units.length - 1;k > 0;k--) {
          if(units[k-1]['unit'] != '')
            break;
          else {
            this.deleteRow(k);      
            units.pop();
          }
        }
        
          
        for(i=0;i<units.length;i++) {
          if(!$('#{object_name}_#{field_name}_' + i)) {
            this.addRow('','',i);
          }
          $('#{object_name}_#{field_name}_' + i).value = units[i]['unit'];
          $('#{object_name}_#{price_name}_' + i).value = units[i]['price'];
          if(i > 0)
            $('#{object_name}_#{field_name}_min_' + i).innerHTML = units[i-1]['unit'];
        }
        
        // Delete the last two %= %
      
      },
      
      
      addRow: function(unit,price,index) {
        var last_val = Number(0.0).toFixed(#{options[:field_units] || 1});
        if(index > 0 && $('#{object_name}_#{field_name}_' + (index-1)))
            last_val = $('#{object_name}_#{field_name}_' + (index-1)).value;
            
        var rw = Builder.node('tr', { id: "#{object_name}_#{field_name}_row_" + index },
                [ Builder.node('td',{ style: 'text-align:right;' },
                   [ Builder.node('span', { id: '#{object_name}_#{field_name}_min_' + index }, last_val), " #{options[:units]}" ] ),
                  Builder.node('td', ' - '),
                  Builder.node('td',
                    [ Builder.node('input', { type:'text', size:'5', id:'#{object_name}_#{field_name}_' + index, style:'text-align:right;',
                                              name:'#{object_name}[#{field_name}][]',
                                              onchange:'#{object_name}_#{field_name}_editor.changedUnit(this); return false;',
                                              value:unit }),
                      " #{options[:units]}"]),
                  Builder.node('td',{ style:"padding-left:30px;"},
                    [ " #{options[:currency][0]}",
                      Builder.node('input', { type: 'text', style:'text-align:right;',
                                              name: '#{object_name}[#{price_name}][]',
                                              id: '#{object_name}_#{price_name}_' + index,
                                              onchange:'#{object_name}_#{field_name}_editor.changedPrice(this); return false;',
                                              size:5, value:price }),
                     "#{options[:currency][1]}" ])
                  ]);
        $("#{object_name}_#{field_name}_table").appendChild(rw);
      },
      
      deleteRow: function(index) {
        var tbl = $("#{object_name}_#{field_name}_table");
        tbl.deleteRow(index);
      }
      
   
    }    
    </script>    
    <table >
      <tbody id="#{object_name}_#{field_name}_table" >
      </tbody>
    </table>
    <script type='text/javascript'>
      #{(0..price_values.length-1).to_a.collect { |index| "#{object_name}_#{field_name}_editor.addRow('#{field_values[index]}','#{price_values[index]}',#{index});\n" } } 
      #{object_name}_#{field_name}_editor.updateUnits();
    </script>

    SRC
  end
  
  
  def price_classes(field,classes,opts = {})
  
    options = { 
                :currency => opts[:currency] || ['$',''] 
              }
  
    class_html = ''
    classes.each do |cls|
      class_html += "<tr><td>#{cls[0]}:</td>"
      class_html += "<td style='padding-left:20px;'>"
      class_html += "#{options[:currency][0]}<input style='text-align:right;' type='text' size='5' name='#{@object_name}[#{field}][#{cls[1].to_s}]'value='#{(@object.send(field)||{})[cls[1].to_s]}' onchange='this.value = Number(this.value).toFixed(2);' />#{options[:currency][1]}</td></tr>"
    end    
    <<-SRC
    <table>
      #{class_html}
    </table>
    SRC
  end
  
  # Display a image list, stored in a single text field
  def image_list(field,opts={})
    obj_name = @object_name.to_s.gsub(/\[|\]/,"_");
    
    val = @object.send(field).to_s.split(",").find_all { |elm| elm.to_i > 0 }
    if val.length > 0
      df = DomainFile.find(:all,:conditions => ["id IN (?)",val])
      
      files = df.collect do |fl|
        file_id = fl.id
        html = nil
        if fl
          html = "<div class='attachment' id='#{@object_name}_#{field}_attachment_#{fl.id}'><table><tr><td>"        
          if fl.file_type == 'doc'
            html += "<img id='#{@object_name}_#{field}_handle_item_#{fl.id}' src='#{@template.controller.theme_src("/images/icons/filemanager/document.gif")}' align='top' width='64' height='64'/>"
          elsif fl.file_type == 'img' || fl.file_type == 'thm'
            html += "<div class='fm_image' id='#{@object_name}_#{field}_handle_item_#{fl.id}' ><img src='#{fl.url(:thumb)}' align='middle' id='#{field}_thumb_image_#{fl.id}'/></div>"
          end
          html += "</td><td><a href='javascript:void(0);' onclick='image_list_#{obj_name}_#{field}.showAttachmentPopup(\"#{fl.id}\");'>#{h(fl.name)}</a></td></tr></table></div>"
        end
        html
      end
    else
      files = ""
    end
    
    
    link_txt = link_to('+Add Image'.t, "/website/file/popup?select=img&callback=image_list_#{obj_name}_#{field}.attachFile&thumb_size=thumb", :popup => ['file_manager', 'height=500,width=900,resizable=yes,scrollbars=yes' ])
    
     <<-JAVASCRIPT
        <script type='text/javascript'>
          var image_list_#{obj_name}_#{field} = {
             attachFile: function(field,type,id,path,url,thumb,name) {
                this.removeAttachment(id);
                var code = "<table><tr><td>";
                
                if(type != 'img') {
                  code +=  "<img id='handle_item_" + id + "' src='" + thumb + "' align='top' width='64' height='64'>";
                }
                else {
                  code +=  "<div class='fm_image'><img src='" + thumb + "'  align='middle'></div>";
                }
                
                code += " </td><td><a href='javascript:void(0);' onclick='image_list_#{obj_name}_#{field}.showAttachmentPopup(" + id + ");'>" + name + "</a></td></tr></table></div>";
                
                var elem = document.createElement('div');
                elem.id = '#{@object_name}_#{field}_attachment_' + id;
                elem.className="attachment";
                elem.innerHTML = code;
                
                 $('image_list_#{@object_name}_#{field}').appendChild(elem);
                this.recreateSortable();
                this.updateFieldValue();
                
              },
              
             recreateSortable: function() {
                Sortable.create('image_list_#{@object_name}_#{field}', { tag: 'div', onUpdate: image_list_#{obj_name}_#{field}.updateFieldValue  });
             },
             
             updateFieldValue: function() {
                var images = $('image_list_#{@object_name}_#{field}').select(".attachment").collect(function(elem) {
                var name = elem.id.split("_");
                return name[name.length - 1];
                });
                $('#{@object_name}_#{field}').value = images.join(",");
             },
      
             showAttachmentPopup: function(aid) {
               SCMS.popup(new Array(
                [ 'Remove Attachment', 'js', 'image_list_#{obj_name}_#{field}.removeAttachment(' + aid + ')' ]
              )); 
            },
  
            removeAttachment: function(id) {
              if($('#{@object_name}_#{field}_attachment_' + id)) {
                Element.remove('#{@object_name}_#{field}_attachment_' + id);
                this.recreateSortable();
                this.updateFieldValue();
              }
            }
          };
        </script>
        #{link_txt}
        <div id='image_list_#{@object_name}_#{field}' style='min-height:80px; border:1px solid #000000;  margin:3px;  overflow:auto;'>
        #{files}
       </div>
       <input type='hidden' name='#{@object_name}[#{field}]' id='#{@object_name}_#{field}' value='#{val.join(",")}'/>
       <script type='text/javascript'>
        image_list_#{obj_name}_#{field}.recreateSortable();
       </script>
    JAVASCRIPT
  
  end
  
  # Displays a autocomplete-powered selector for a user
  # By default if expects a field called 'field' and one called 'field_id'
  # but passing a :no_name => true option will just use field as the id field
  #
  # You can also pass in a :id_field attribute to use a different id field name
  def end_user_selector(field,opts = {})
      
      if opts[:no_name]
        id_field = field
        field = "#{id_field}_name"
      else
        id_field = opts[:id_field] || "#{field}_id"
      end
      
      if id_field
        id_value = @object ? @object.send(id_field) : ''
        usr = EndUser.find_by_id(id_value)
        if usr
          value = usr.name
        elsif !opts[:no_name]
          value = @object ? @object.send(field) : ''
        end
      else
        value = @object ? @object.send(field) : ''
      end
      
      field_id = "#{@object_name}_#{field}"
      if opts[:no_name]
        field_name = "#{@object_name}_#{field}_selector"
      else
        field_name = "#{@object_name}[#{field}]"
      end
      
      id_field_id = "#{@object_name}_#{id_field}"
      ok_icon_id = "#{@object_name}_#{field}_ok"
      id_field_name = opts[:id_field_name] || "#{@object_name}[#{id_field}]"


      
       <<-JAVASCRIPT
        <span class='data text_field_control'><input type='text' style='width:280px;' id='#{field_id}' name='#{field_name}' class='text_field' value='#{h value}' onkeyup="if($('#{id_field_id}_temp').value != this.value) { $('#{id_field_id}').value=''; $('#{ok_icon_id}').style.visibility='hidden'; }" />
    <input type='hidden' name='#{id_field_name}' value='#{id_value}' id='#{id_field_id}'/>
    <input type='hidden' value='#{h value}' id='#{id_field_id}_temp'/>
    <img src='#{@template.controller.theme_src('icons/ok.gif')}' id='#{ok_icon_id}' style='#{"visibility:hidden;" unless usr}' /></span>
    <div class='autocomplete' id='#{field_id}_autocomplete' style='display:none;' ></div>
    
    <script type='text/javascript'>
      var autocomplete = new Ajax.Autocompleter('#{field_id}','#{field_id}_autocomplete','#{@template.controller.url_for(:controller => '/members', :action => 'lookup_autocomplete')}',{ minChars: 2, paramName: 'member', afterUpdateElement: function(text,li) { 
        $('#{field_id}').value = li.select(".name")[0].innerHTML; 
        $('#{id_field_id}_temp').value = li.select(".name")[0].innerHTML; 
        $('#{ok_icon_id}').style.visibility='visible';
        $('#{id_field_id}').value = SCMS.getElemNum(li);
        }
      });
    </script>
      
  JAVASCRIPT
  end
    
  # Generic autocomplete field
  def autocomplete_field(field,url,opts = {})

          
      value = @object ? @object.send(field) : ''
      
      field_id = "#{@object_name}_#{field}"
      if opts[:no_name]
        field_name = "#{@object_name}_#{field}_selector"
      else
        field_name = "#{@object_name}[#{field}]"
      end
      
      multiple = opts.delete(:multiple)
      callback = opts.delete(:callback)
    
      type = opts.delete(:type) || 'text'
      if type == 'text'
        text_field = tag(:input,{:type=>'text',:style => 'width:280px;',
          :id => field_id,:name => field_name,:class=>'text_field',:value => h(value) }.merge(opts.delete(:html) || {}))
      elsif type=='textarea'
        text_field = content_tag(:textarea,h(value), {:style => 'width:280px;',
          :id => field_id,:name => field_name,:class=>'text_field' }.merge(opts.delete(:html) || {}))
      end
       <<-JAVASCRIPT
        <span class='data text_field_control'>#{text_field}</span>
        <div class='autocomplete' id='#{field_id}_autocomplete' style='display:none;' ></div>
      
    <script type='text/javascript'>
      var autocomplete = new Ajax.Autocompleter('#{field_id}','#{field_id}_autocomplete','#{url}',{ minChars: 3, paramName: '#{field_id}', #{"tokens: ','," if multiple} select: 'display_value' #{",afterUpdateElement: #{callback}" if callback}
      });
    </script>
  JAVASCRIPT
  
  end
  
  def root_page_selector(field,opts = {})
    self.select(field,SiteNode.page_options('--Add to site root--'.t),opts)
  end
 
  # Selector that lets you pick a page by id
  def page_selector(field,opts = {}, html_options={})
    self.select(field,[['--Select Page--'.t,nil]] + SiteNode.page_options,opts,html_options)
  end
 
  # Selector that lets you pick a page by url
 def url_selector(field,opts = {})
    self.select(field,[['--Select Page--'.t,nil]] + SiteNode.page_options.map {  |elm| [elm[0],elm[0]] },opts)
  end


  def rating_field(field,opts = {})
    rating = @object ? @object.send(field) : 0
    field_id = "#{@object_name}_#{field}"

    active_rating_widget(rating,:callback => "setRating#{field_id}(",
                          :icon => '/themes/standard/images/icons/star_unselected.gif',
                          :selected => '/themes/standard/images/icons/star_selected.gif') + self.hidden_field(field) + 
      "<script> function setRating#{field_id}(num) { document.getElementById('#{field_id}').value = num; }</script>"
  end

  # Ordered array selector that lets elements be added and sorted.
  # Posts as an array of elements similar to a multiselect.
  # Accepts a list of opts like select and radio_buttons does
  def ordered_array(field,opts,options={})
    objects = @object.send(field)

    select_options = ''
    opts_hash = {}

    if options[:grouped]
      # options for select doesn't support disabled arguments, so ryo
      select_options = opts.map do |section|
        group_options = section[1].map do |opt|
          opts_hash[opt[1]] = opt[0].to_s
          opt_disabled = objects.include?(opt[1]) ? 'disabled="disabled"' : ''
          "<option value='#{opt[1]}' #{opt_disabled}>#{h(opt[0])}</option>"
        end.join
        "<optgroup label=\"#{h section[0]}\">#{group_options}</optgroup>"
      end.join
      select_options = "<option value=''>" + '--Select--'.t + "</option>#{select_options}"
    else
      # options for select doesn't support disabled arguments, so ryo
      select_options = ([['--Select--'.t,nil]] + opts).map do |opt|
        opts_hash[opt[1]] = opt[0].to_s
        opt_disabled = objects.include?(opt[1]) ? 'disabled="disabled"' : ''
        "<option value='#{opt[1]}' #{opt_disabled}>#{h(opt[0])}</option>"
      end.join
    end

    obj_name = @object_name.to_s.gsub(/\[|\]/,"_");
    idx=-1
    existing_options = objects.map do |elm|
      idx+=1
      <<-TXT
      <div class='ordered_selection_list_item' id='#{obj_name}_#{field}_element_#{idx}'>
<div class='ordered_selection_list_remove'><a href='javascript:void(0);' onclick='OrderedArray.delete("#{obj_name}_#{field}","#{@object_name}[#{field}]","#{idx}","#{ elm}");'>X</a></div><div class='ordered_selection_list_value' id='ordered_selection_list_item_#{elm}'>#{h opts_hash[elm]}</div>
       </div>
TXT
    end.join
      
    html = <<-HTML
<script type='text/javascript'>
  OrderedArray = {
     add:function(name,obj_name) {
       var idx= $(name + "_select").selectedIndex;

       if(idx!=0) {	    
        var option = $(name + "_select").options[idx];

        if(!option.value) return;
        option.disabled = true;
        
        $(name + "_select").selectedIndex = 0;

        var existing =  $(name + "_selector").select(".ordered_selection_list_item");
        var index =1;
        if(existing.length > 0) {
          index = existing.map(function(elm) { return SCMS.getElemNum(elm.id); }).max() + 1;
        }
           
        var html = "<div class='ordered_selection_list_item' id='" + name + "_element_" + index + "'>";
        html += "<div class='ordered_selection_list_remove'><a href='javascript:void(0);' onclick='OrderedArray.delete(\\"" + name + "\\",\\"" + obj_name + "\\",\\"" + index +  "\\",\\"" + option.value + "\\");'>X</a></div>";
        html += "<div class='ordered_selection_list_value' id='ordered_selection_list_item_" + option.value + "'>" +  option.text.escapeHTML() + "</div>";
        html +="</div>";
        $(name + '_selector').insert(html);
        $(name + '_selector').show();

  
        OrderedArray.createSortables(name,obj_name);
      }
			
     },

     createSortables:function(name,obj_name) {
       Sortable.create($(name + "_selector"),{
               tag: 'div',
               constraint: 'vertical',
               dropOnEmpty: true,
               onUpdate: function() { OrderedArray.refreshPositions(name,obj_name); }
       });
       OrderedArray.refreshPositions(name,obj_name);
     },

    refreshPositions:function(name,obj_name) {
        $(name + "_positions").innerHTML = null;
        var elems = $(name + "_selector").select('.ordered_selection_list_value');

        output = "";
        var reg = /^ordered_selection_list_item_/
      
         elems.each(function(elem) {
           var str = elem.id.replace(reg, "")
           output += "<input type='hidden' name='" + obj_name + "[]' value='" + str.escapeHTML() +  "'/>"; 
         });

         $(name + "_positions").innerHTML = output;

    },


    delete: function(name,obj_name,index,obj_id) {
      $(name + '_element_' + index).remove();
      var opts = $(name + "_select").options;

      for(var i=0;i<opts.length;i++) {
        if(opts[i].value == obj_id)
            opts[i].disabled = false;
      }
       OrderedArray.refreshPositions(name,obj_name);
    }
	
   }
</script>
      <select name='#{obj_name}_#{field}_select' id='#{obj_name}_#{field}_select'>#{select_options}</select>
      <button id='#{obj_name}_#{field}_add' onclick='OrderedArray.add("#{obj_name}_#{field}","#{@object_name}[#{field}]"); return false;' >Add</button><br/>
      <div id='#{obj_name}_#{field}_positions'></div>
      <div class='ordered_selection_list' id='#{obj_name}_#{field}_selector' #{"style='display:none;'" if objects.length == 0}>
        #{existing_options}
      </div>
#{    "<script type='text/javascript'>OrderedArray.createSortables('#{obj_name}_#{field}','#{@object_name}[#{field}]');</script>"}
HTML
         
  end

  
  def ordered_selection_list(field,class_name,options={}) #:nodoc:

    opts = options.delete(:options)
    opts = class_name.select_options if !opts

    id_field = options.delete(:id_field)
    id_field = class_name.to_s.underscore + "_id" unless id_field

    sortable = options.has_key?(:sortable) ? options.delete(:sortable) : true

    if sortable 
      position_field = options.delete(:position_field)
      position_field = "position" unless position_field
    end

    objects = @object.send(field)

    disabled = objects.map(&id_field.to_sym)

    # options for select doesn't support disabled arguments, so ryo
    select_options = ([['--Select--'.t,nil]] + opts).map do |opt|
      opt_disabled = disabled.include?(opt[1]) ? 'disabled="disabled"' : ''
      "<option value='#{opt[1]}' #{opt_disabled}>#{h(opt[0])}</option>"
    end.join

    obj_name = @object_name.to_s.gsub(/\[|\]/,"_");

    idx=-1
    existing_options = @object.send(field).map do |elm|
      idx+=1
      <<-TXT
      <div class='ordered_selection_list_item' id='#{obj_name}_#{field}_element_#{elm.send(id_field)}'>
<div class='ordered_selection_list_remove'><a href='javascript:void(0);' onclick='OrderedList.delete("#{obj_name}_#{field}", "#{elm.send(id_field)}");'>X</a></div>
           #{h elm.name}
           <input type='hidden' name='#{@object_name}[#{field}][][#{id_field}]' value='#{elm.send(id_field)}' />
           #{"<input type='hidden' name='#{@object_name}[#{field}][][#{position_field}]' value='#{elm.send(position_field)}' />" if sortable}
       </div>
TXT
    end.join
      
    html = <<-HTML
<script type='text/javascript'>
  OrderedList = {
     add:function(name,obj_name,id_field,position_field) {
       var idx= $(name + "_select").selectedIndex;

       if(idx!=0) {	    
        var option = $(name + "_select").options[idx];

        if(!option.value) return;
        option.disabled = true;
        
        $(name + "_select").selectedIndex = 0;

           
        var position = $(name + '_selector').select(".ordered_selection_list_item").length + 1;
 
        var html = "<div class='ordered_selection_list_item' id='" + name + "_element_" + option.value + "'>";
        html += "<div class='ordered_selection_list_remove'><a href='javascript:void(0);' onclick='OrderedList.delete(\\"" + name + "\\",\\"" + option.value + "\\");'>X</a></div>";
        html +=  option.text;
        html += "<input type='hidden' name='" + obj_name + "[][" + id_field + "]' value='" + option.value + "'/>";
        if(position_field)
           html += "<input type='hidden' name='" + obj_name + "[][" + position_field + "]' value='" + position  + "'/>";
        html +="</div>";
        $(name + '_selector').innerHTML += html;
        $(name + '_selector').show();

  
        if(position_field) OrderedList.createSortables(name,obj_name);
      }
			
     },

     createSortables:function(name,obj_name) {
       Sortable.create($(name + "_selector"),{
               tag: 'div',
               constraint: 'vertical',
               dropOnEmpty: true,
               onUpdate: function() { OrderedList.refreshPositions(name); }
       });
     },


    delete: function(name,obj_id) {
      $(name + '_element_' + obj_id).remove();
      var opts = $(name + "_select").options;

      for(var i=0;i<opts.length;i++) {
        if(opts[i].value == obj_id)
            opts[i].disabled = false;
      }

      OrderedList.refreshPositions(name);

    },

    refreshPositions: function(name) {
      var selector = $(name + '_selector');
      var elements = selector.select('.ordered_selection_list_item');
      for(var i=0;i<elements.length;i++) {
        elements[i].select('input')[1].value = i+1;
      }

    }
   }
</script>
      <select name='#{obj_name}_#{field}_select' id='#{obj_name}_#{field}_select'>#{select_options}</select>
      <button  id='#{obj_name}_#{field}_add'  onclick='OrderedList.add("#{obj_name}_#{field}","#{@object_name}[#{field}]","#{id_field}","#{position_field}"); return false;' >Add</button><br/>
       <input type='hidden' name='#{@object_name}[#{field}][][#{id_field}]' value='' />
      <div class='ordered_selection_list' id='#{obj_name}_#{field}_selector' #{"style='display:none;'" if objects.length == 0}>
        #{existing_options}
      </div>
#{    "<script type='text/javascript'>OrderedList.createSortables('#{obj_name}_#{field}','#{@object_name}[#{field}]');</script>" if sortable}
HTML
     

  end

  # Access control widget that expected a boolean field 
  # where SiteAuthorizationEngine::Target#access_control has been called.
  # Used to optionally limit access on a piece of content
  #
  # Message should be something like: "Limit access to this Blog Post"
  # and it will appear next to a checkbox to optionally limit access.
  def access_control(field,message,options={})

    options = options.clone
    options.symbolize_keys!
    options[:single] = true

    output = ""
    opts = options.clone
    opts.symbolize_keys!
    opts[:class] = 'check_box'
    opts[:onclick] = "$('#{@object_name}_#{field}_access').style.display = this.checked ? '' : 'none';"

    output += hidden_field_tag("#{@object_name}[#{field}]",'',:id => "#{@object_name}_#{field}_empty")

    
    checked = @object.send("#{field}?") if @object

    output += "<label class='check_box'>" + 
      check_box_tag("#{@object_name}[#{field}]", 1,checked,opts) + " " + 
      emit_label(message.to_s.gsub("\n","<br/>")).gsub("&lt;br/&gt;","<br/>") +
      "</label>"
    output += "<br/>"

    display = checked ? "" : "style='display:none;'"
    output += "<div id='#{@object_name}_#{field}_access' #{display}>"
    available_actors = Role.authorized_options(true)
    output += ordered_selection_list_original("#{field}_authorized",UserClass,:id_field => 'identifier',:options => available_actors,:sortable => false)
    output += "</div>"

  end

  def captcha(field, captcha, options={})
    captcha.generate(options)
  end


  def add_page_selector(field,options={ })

    self.select_original("#{field}_id",SiteNode.page_options('--Add to Site Root--'.t)) +
      " / " +
      self.text_field_original("#{field}_subpage",:size => 10, :disabled => !@object.send("#{field}_existing").blank?) + 
    "<br/>" + 
    self.check_boxes_original("#{field}_existing", [["Add to an existing page",true]], :single => true, :onclick => " $('#{object_name}_#{field}_subpage').disabled = this.checked")
  end

  def inline_file_upload(field, options={})
    options[:width] ||= '100%'
    options[:height] ||= 50
    options[:frameborder] ||= 0
    options[:marginwidth] ||= 0
    options[:marginheight] ||= 0
    options[:name] = "#{@object_name}_#{field}_frame"
    options[:id] = options[:name]

    url = options.delete(:url)
    url += "?upload=1&file[object]=#{@object_name}&file[field]=#{field}"
    url += '&' + options.delete(:params).collect { |k,v| "#{k}=#{CGI::escape(v)}" }.join('&') if options[:params]

    value = @object.send(field)
    preview = ''
    unless value.blank?
      file_field = field.to_s.sub /_id$/, ''
      file = @object.send(file_field)
      preview = "<img src='#{file.thumbnail_url('standard/', :thumb)}' /> #{file.name}"
    end

    output = hidden_field field
    output += "<span class='inline_file_preview' id='#{object_name}_#{field}_preview'"
    output += ' style="display:none;"' if value.blank?
    output += "><span id='#{object_name}_#{field}_preview_content'>#{preview}</span> "
    output += content_tag :a, 'clear'.t, {:class => 'inline_file_clear', :href => 'javascript:void(0);', :onclick => "$('#{object_name}_#{field}').value = ''; $('#{object_name}_#{field}_preview_content').innerHTML = ''; $('#{object_name}_#{field}_preview').hide(); $('#{object_name}_#{field}_frame').show(); $('#{object_name}_#{field}_frame').src = $('#{object_name}_#{field}_frame').src;"}
    output += "</span>"
    output += "<iframe src='#{url}' "
    output += options.collect { |k,v| "#{k}='#{v}'" }.join(' ')
    output += ' style="display:none;"' unless value.blank?
    output += '></iframe>'
  end
end
