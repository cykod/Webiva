CmsGallery = { 

  maxImageHeight:null,
  maxImageWidth:null,
  galleryId:null,
  imageIdx:null,

  preloadOverlay: function(url) {
    new Ajax.Request(url);
  },

  overlayDisplay: function(gallery_id,image_idx) {
    var images = CmsGalleryImages["" + gallery_id];
    
    if(image_idx >= images.length)
      return null;
    if($('RB_window')) {
        $('RB_window').innerHTML = '';
    }
    
    if($('Gallery_overlay_hidden')) {
      Element.remove('Gallery_overlay_hidden');
    }
  
    RedBox.loading();
    RedBox.showOverlay();

    nd = Builder.node('div', { id: 'Gallery_overlay_hidden', style: 'display:none;' });
    var body = document.getElementsByTagName('body');
    body[0].appendChild(nd);
    
    var container = CmsGallery.overlayContainer(gallery_id,image_idx);
    nd.appendChild(container);
    
    CmsGallery.displayImage(gallery_id,image_idx);
    
    nd.appendChild(container);
    
    RedBox.addHiddenContent('Gallery_overlay_hidden'); 
  },

overlayBrowse: function(pos) {
    var image_pos = CmsGallery.imageIdx + pos;
    
    var previous_image_id = 'cms_gallery_image_' + CmsGallery.galleryId + "_" + CmsGallery.imageIdx;
    //if($(previous_image_id)) {
    //  Element.hide(previous_image_id);
    //}
    
    CmsGallery.displayImage(CmsGallery.galleryId,image_pos);
    
    setTimeout(function() { CmsGallery.preloadImage(CmsGallery.galleryId,image_pos+(pos > 0 ? 1 : -1)); },10);
    
  },
  
  preloadImage: function(gallery_id,image_idx) {
    var image_id = 'cms_gallery_image_' + gallery_id + "_" + image_idx;
    if(!$(image_id)) {
    
      var images = CmsGalleryImages["" + gallery_id];
      
      if(image_idx >= images.length)
        return;
          
      if(image_idx < 0)
        return;
        
       var img = images[image_idx];
       
       if(!img.image) {
	img.image = new Image();
        img.image.onload = function() {
           img.loaded = true;
        }
	img.image.src = img.url;
      }
       
       //var image_div = CmsGallery.loadImage(gallery_id,image_idx,false);
       //$('cms_gallery_images').appendChild(image_div);
    }
  
  },

  displayImage: function(gallery_id,image_idx) {
  
    
    
    var image_id = 'cms_gallery_image_' + gallery_id + "_" + image_idx;
    
    var images = CmsGalleryImages["" + gallery_id];
    var img = images[image_idx];
    
    if(img.image && !img.loaded) {
      $('cms_gallery_back').style.visibility = 'hidden';
      $('cms_gallery_forward').style.visibility = 'hidden';
      setTimeout(function() { CmsGallery.displayImage(gallery_id,image_idx); }, 100);
      return;
    }
    else if(!img.image) {
      $('cms_gallery_back').style.visibility = 'hidden';
      $('cms_gallery_forward').style.visibility = 'hidden';
      CmsGallery.preloadImage(gallery_id,image_idx);
      setTimeout(function() { CmsGallery.displayImage(gallery_id,image_idx); }, 100);
      return;

    }

    
    var image_div = CmsGallery.loadImage(gallery_id,image_idx,true);
    $('cms_gallery_images').innerHTML = '';
    $('cms_gallery_images').appendChild(image_div);
    
    CmsGallery.imageIdx = image_idx;
    CmsGallery.galleryId = gallery_id;
    
    
    $('cms_gallery_image_name').innerHTML = img.name;
    $('cms_gallery_page').innerHTML = (image_idx+1) + "/" + images.length;
    back_visibility = (image_idx == 0) ? 'hidden' : '' ;
    forward_visibility = (image_idx >= (images.length - 1))  ? 'hidden' : '' ;
    $('cms_gallery_back').style.visibility = back_visibility;
    $('cms_gallery_forward').style.visibility = forward_visibility;
  },

  loadImage: function(gallery_id,image_idx,show) {
  
      var images = CmsGalleryImages["" + gallery_id];
      
      if(image_idx >= images.length)
        return null;
        
      if(image_idx < 0)
        return null;
        
      
      var img = images[image_idx];
      
      var url = img.url;
      var width = img.width;
      var height = img.height; 
      
      var orig_width = width;
      var orig_height = height;
      
      var vert_scale = (CmsGallery.maxImageHeight - 12)/ orig_height;
      var horiz_scale = (CmsGallery.maxImageWidth - 6 ) / orig_width;
      
      var scale = horiz_scale < vert_scale ? horiz_scale : vert_scale;
      
      var scaleFactor = 100;
      if(scale < 1.0) {
        width = width * scale;
        height = height * scale;
        
        scaleFactor = Math.round(scale * 100);
      
      }
      
      var new_image;
      if(document.all) 
        new_image = new Image(width,height);
      else {
        new_image = document.createElement('img');
        new_image.width = width;
        new_image.height = height;
      }
      
      
      new_image.setAttribute('src',url);
      
      
      new_image.style.padding = '0px;';
      new_image.style.margin = '0px';
      new_image.style.border = '0';
      
      var image_id = 'cms_gallery_image_' + gallery_id + "_" + image_idx;

      new_image.setAttribute('id',image_id + '_image');
      
      
      
      
      show = ''; //show ? '' : 'display:none;';
      image_height_area = CmsGallery.maxImageHeight - height - 12;
      padding_top = Math.round((image_height_area) / 2);
      padding_bottom = image_height_area - padding_top;
      image_width_area = CmsGallery.maxImageWidth - width - 6;
      padding_left = Math.round((image_width_area) / 2);
      padding_right = image_width_area - padding_left;
      var div  = Builder.node('div', { id: image_id, style: show + ' text-align:left; position:relative; padding:0px; margin:' + padding_top + 'px ' + padding_right +'px ' + padding_bottom + 'px ' + padding_left + 'px;'}, 
                  [ Builder.node('div', { className: 'cms_gallery_shadow' }, [
                      Builder.node('div', {}, [
                        Builder.node('p', {}, [ new_image ] )
                       ])
                     ]),
                   Builder.node('div', { style: 'clear:both;' })
                   ]);
       
      
      return div;
  },


  overlayContainer: function(gallery_id,image_idx) {
  
    var images = CmsGalleryImages["" + gallery_id];
  
    var pageSize = RedBox.getPageSize();
    var box_width = Math.round(pageSize[0] * .60 - 20);
    var box_height = Math.round(pageSize[1] * .80 - 20);
    
    CmsGallery.maxImageWidth = box_width-10;
    CmsGallery.maxImageHeight= box_height-10;
    
    
    var container = Builder.node('div', { style: 'margin:0px; padding:20px; background-color:white; border:1px solid #000000;  width:' + box_width + 'px; height:' + box_height + 'px;' });
    var actions = Builder.node('div', { style: 'text-align:left; position:relative;' } );
    var actionHTML =  ""
    
    actionHTML += "<div style='position:absolute; top:0px; left:0px; height:" + (CmsGallery.maxImageHeight+12) + "px; width:" + (CmsGallery.maxImageWidth+6) + "px; padding:0px; margin:0px;' id='cms_gallery_images'></div>";
    //actionHTML += "<tr><td colspan='5' valign='middle' align='center' height='" + CmsGallery.maxImageHeight + " width='" + CmsGallery.maxImageWidth + "'><div style='padding:0px; margin:0px;' id='cms_gallery_images'></div></td></tr>"
    
    actionHTML += "<div style='position:relative; top:" + CmsGallery.maxImageHeight + "px;'><table style='padding-top:5px;' width='100%' cellspacing='0' cellpadding='0'>";
    
    
    actionHTML  += "<tr><td width='100%'><div id='cms_gallery_image_name'></div></td>";
    actionHTML  += "<td nowrap='1' style='padding-right:15px;'><div id='cms_gallery_page'>" + (image_idx+1) + "/" + images.length + "</div></td>";
    var hide_back = (image_idx == 0) ? 'style="visibility:hidden;"' : '';
      actionHTML  += "<td><a href='javascript:void(0);' id='cms_gallery_back' " + hide_back + " onclick='CmsGallery.overlayBrowse(-1);'><img src='/images/site/gallery/image_back.png' border='0' width='29' height='22'/></a></td> ";
    var hide_forward = (image_idx >= (images.length - 1)) ? 'style="visibility:hidden;"' : '';
      actionHTML  += "<td><a href='javascript:void(0);' id='cms_gallery_forward' " + hide_forward + " onclick='CmsGallery.overlayBrowse(1);'><img src='/images/site/gallery/image_next.png' border='0' width='29' height='22'/></a></td> ";
      
    actionHTML  += "<td style='padding-left: 50px;'><a href='javascript:void(0);' onclick='CmsGallery.close();'><img src='/images/site/gallery/image_close.png' border='0px'/></a>";
    actionHTML += "</td></tr></table>";
    
    actionHTML +="</div>";
    
    actions.innerHTML = actionHTML;
    
    container.appendChild(actions);
    
    return container;
  },

 close: function() {
    $('Gallery_overlay_hidden').remove();
    RedBox.close();  
  },
  
  editInfo: function(gallery_id,image_idx) {
    var images = CmsGalleryImages["" + gallery_id];
    var img = images[image_idx];
  
  
    $('image_image_id').value = img.id;
    $('info_image_' + gallery_id).src = img.thumb;
    $('image_description').value = img.name;
    if($('image_position')) {
      $('image_position').options[image_idx].selected = true;
    }
    
    var content = RedBox.showInline("info_form_" + gallery_id);
    
    if($('image_position')) $('image_position').style.visibility = 'visible';
    setTimeout("$('image_position').selectedIndex=" + image_idx + ";",10);
    
  },
  
  uploadImage: function(gallery_id) {
    RedBox.showInline('upload_form_' + gallery_id);
  
  },
  
  deleteImage:function(gallery_id,image_id) {
    $('delete_image_id_' + gallery_id).value = image_id;
    if($('delete_image_form_' + gallery_id).onsubmit()) {
      setTimeout("$('delete_image_form_" + gallery_id + "').submit();",10);
    }
  
  },
  
  cancelInfo: function() {
   $('RB_window').innerHTML='';
   RedBox.close();
  
  },
  
  cancelUpload:function() {
   $('RB_window').innerHTML='';
   RedBox.close();
  
  }
  
}

CmsGalleryImages = $H({});
