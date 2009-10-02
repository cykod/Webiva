var WebivaMenu = {

  preloads: [],
  
  curPopup: {},
  curPopupImg: {},

  restoreImage: function(obj,popup) { 
    if(WebivaMenu.curPopup[popup])
      return;
    if(obj && obj.old_src) {
       obj.src = obj.old_src;
    }
  },
  
  swapImage: function(obj,cur_img,new_img,popup) { 
   obj.old_src = cur_img;
   obj.src = new_img;
   if(popup)
     WebivaMenu.curPopupImg[popup] = obj;
  },
  
  preloadImage: function(img_src) {
    var image = new Image();
    image.src = img_src;
    WebivaMenu.preloads.push(image);
  },

  
  findPos: function(obj) {
    var cur_obj = obj;
    var left = 0;
    var top = 0;
    while (cur_obj){
      left += cur_obj.offsetLeft;
      top += cur_obj.offsetTop;
      cur_obj = cur_obj.offsetParent;
    }
    if (navigator.userAgent.indexOf('Mac') != -1 && typeof document.body.leftMargin != 'undefined'){
      left += document.body.leftMargin;
      top += document.body.topMargin;
    }  
    return [left,top];
  },
  
  resetElement: function(obj,parent,options) {
    var offset_x=0;
    var offset_y=0;
    var position='bottom_left';
    if(options ) {
      if(options.position)
        position = options.position;
      if(options.offset_y) 
        offset_y = options.offset_y;
      if(options.offset_x) 
        offset_x = options.offset_x;
    }
      
    var cur_parent = obj.parentNode;
    // Remove the element from it's current parent
    cur_parent.removeChild(obj);
    
    // Get the position of the new parent element
    var pos = WebivaMenu.findPos(parent);
    
    // Add in the offsetWidth + offsetHeight of the element
    var pos_x = pos[0];
    var pos_y = pos[1];
    switch(position) {
    case 'bottom_left':
      pos_y += parent.offsetHeight;
      break;
    case 'bottom_right':
      pos_x += parent.offsetWidth;
      break;
    case 'top_right':
      pos_x += parent.offsetWidth;
      break;
    case 'top_left':
      break;
    }
    
    pos_x += offset_x;
    pos_y += offset_y;
    
    
    // create the global popup div if necessary
    var container = WebivaMenu.createPopupDiv();
    
    obj.style.position='absolute';
    
    // position the object absolutely
    container.appendChild(obj);
    obj.style.left = pos_x + 'px';
    obj.style.top = pos_y + 'px';
    // show the object
  
  },
  
  createPopupDiv: function() {
    var elem = document.getElementById('webiva_popup');
    if(elem)
      return elem;
      
    var body = document.getElementsByTagName("body")[0];
    var elem = document.createElement("div");
    elem.id = 'webiva_popup';
    
    elem.style.position = 'relative';
    elem.style.left = '0px';
    elem.style.top = '0px';
    elem.style.zIndex = '1000';
    
    var elem = body.insertBefore(elem,body.childNodes[0]);
    
    elem.style.position = 'relative';
    elem.style.left = '0px';
    elem.style.top = '0px';
    elem.style.zIndex = '1000';

    return elem;
  },
  
  
  popupDiv: function(elem_id,parent_elem,options)  {
    var elem = document.getElementById(elem_id);
    if(!elem) {
     return;
    }
    
    WebivaMenu.curPopup[elem_id] = true;

    if(elem.delayedTimer) {
        clearTimeout(elem.delayedTimer);
        elem.delayedTimer = null; 
    }
    
    // Reset the element if necessary
    if(elem.parentNode.id != 'webiva_popup') {
      WebivaMenu.resetElement(elem,parent_elem,options);
    }
    
    elem.onmouseover=WebivaMenu.popupDiv_show;
    elem.onmouseout=WebivaMenu.popupDiv_delayedHide;
    
    WebivaMenu.updateChildNodes(elem,elem);
    setTimeout(function() { elem.style.display='block'; }, 100);
  },
  
  updateChildNodes: function(elem,parent_elem) {
    for(var i=0;i<elem.childNodes.length;i++) {
      try {
      elem.childNodes[i].onmouseover = function() { WebivaMenu.popupDiv_show(parent_elem) };
      elem.childNodes[i].onmouseout = function() { WebivaMenu.popupDiv_delayedHide(parent_elem) };
      } catch(e) {  }
      WebivaMenu.updateChildNodes(elem.childNodes[i],parent_elem);
      
    }
  },
  
  hidePopupDiv: function(elem_id) {
    var elem = document.getElementById(elem_id);
    if(!elem) return;
    
    if(elem.delayedTimer) clearTimeout(elem.delayedTimer);
    elem.delayedTimer = setTimeout("WebivaMenu.popupDiv_delayedHideExecute('" + elem_id + "');",100);
  },
  
  
  popupDiv_delayedHide: function (elem) {
    if(!elem) elem = this;
    if(elem.delayedTimer) clearTimeout(elem.delayedTimer);
    elem.delayedTimer = setTimeout("WebivaMenu.popupDiv_delayedHideExecute('" + elem.id + "');",100);
  },
  
  popupDiv_delayedHideExecute: function(elem_id) {
    var elem = document.getElementById(elem_id);
    if(elem) {
      if(elem.delayedTimer)
        clearTimeout(elem.delayedTimer);
      elem.style.display='none';
      WebivaMenu.curPopup[elem_id] = false;
      WebivaMenu.restoreImage(WebivaMenu.curPopupImg[elem_id],elem_id);
      elem.delayedTimer = null;
   }
  },
  
  popupDiv_show: function(elem) {
    if(!elem) elem = this;
    if(elem.delayedTimer) {
      clearTimeout(elem.delayedTimer);
      elem.delayedTimer = null;
    }
  
  }
};
