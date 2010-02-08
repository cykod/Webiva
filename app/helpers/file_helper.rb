# Copyright (C) 2009 Pascal Rettig.

module FileHelper

  def fm_file_info(file)
    returning file_info = {} do
      %w(id file_type width height processor processor_status url).each { |elm| file_info[elm] = file.send(elm) }
      file_info['short_name'] = file.name
      file_info['name'] = file.file_path
      file_info['thumb_url'] = file.url(:thumb)
      file_info['editor_url'] = file.editor_url
      file_info['private_file'] = file.private?
    end
  end

  def filemanager_register_details(file)
    file_info = fm_file_info(file)
    output = <<-END_OF_SCRIPT
      $('details_#{file.id}').file_info = #{file_info.to_json};
  END_OF_SCRIPT
    output.html_safe
  end

  def filemanager_register_file(file,icon_size,select)  
    additional_adjust = ",#{file.thumb_size(@image_size,@icon_size)[0]},#{file.thumb_size(@image_size,@icon_size)[1]}" if file.file_type == 'img' || file.file_type == 'thm'
    
    file_info = fm_file_info(file)
     file_info['selectable'] = file.file_type_match(select)
    output = <<-END_OF_SCRIPT
    <script>
      $('item_#{file.id}').file_info = #{file_info.to_json};
      $('item_#{file.id}').observe('click',FileEditor.fileClick);
      $('item_#{file.id}').observe('dblclick',FileEditor.fileDblclick);
      FileEditor.last_file_id = #{file.id};
      FileEditor.adjustElementSize($('item_#{file.id}'),#{icon_size}#{additional_adjust });
      Element.show('item_#{file.id}');
    </script>
  END_OF_SCRIPT
    output.html_safe
  end


  def file_manager_image_tag(file,size,icon_size)
    url = file.thumbnail_url(theme,size)
    thumb_size = file.thumbnail_thumb_size(size,icon_size)
    tag("img",
        :title => file.name,
        :src => url + "?" + file.stored_at.to_i.to_s,
        :align => 'middle',
        :id => "thumb_image_#{file.id}",
        :width => thumb_size[0],
        :height => thumb_size[1]
        )
  end
  
  def details_partial(file)
    file.folder? ? '/file/details/folder_details' : '/file/details/file_details.rhtml'
  end
end
