
cmsMenuEdit = {
  clearedCreate:false,
  savedCreate:'',
  lastIndex:0,
  menuEntries:[],
  selectedEntry:null,
  paragraph_id:null,
  para_index:null,

  initialize: function(index,entries) {
    cmsMenuEdit.lastIndex = index;
    Element.hide('cms_loading');
    cmsMenuEdit.clearedCreate =false;
    cmsMenuEdit.menuEntries = entries;
    cmsMenuEdit.recreateSortables();
  },
  
  setParagraph: function(pid,pidx) {
    cmsMenuEdit.paragraph_id = pid;
    cmsMenuEdit.para_index = pidx;
  
  
  },
  
  setSaveUrl: function(url) {
    cmsMenuEdit.saveUrl = url;
  
  },
  
  recreateSortables: function() {
     Sortable.create('cms_menu_entries', 
              { 
                handle:'cms_menu_handle',
                tag:'div',
                onUpdate:cmsMenuEdit.fixLevels,
                constraint: 'vertical', 
                dropOnEmpty:true 
              });
  
  },
  
  addEntry: function(title,dest,value) {
    cmsMenuEdit.menuEntries.push([ title, dest, value, 1 ]);
  },
  
  updateEntry: function(index,title,dest,value) {
    $('cms_item_title_' + index).innerHTML = title;
    cmsMenuEdit.menuEntries[index] = [ title,dest,value,cmsMenuEdit.menuEntries[index][3] ];
  },
  
  clearCreate: function() {
    if(cmsMenuEdit.clearedCreate == false) {
      cmsMenuEdit.savedCreate = $('cms_create_item').value;
      $('cms_create_item').value='';
    }
    cmsMenuEdit.clearedCreate =true;
  },
  
  createEntry: function() {
      var title= $('cms_create_item').value;
      cmsMenuEdit.addEntry(title,'url','');
      $('cms_create_item').value =  cmsMenuEdit.savedCreate ;
      cmsMenuEdit.clearedCreate =false;
      var index = cmsMenuEdit.lastIndex;
      new Insertion.Bottom('cms_menu_entries',
      "<div class='cms_menu_item' id='cms_menu_item_" + index + "' style='padding-left: 10px' >" +
      "<span class='cms_menu_handle'><img src='" + cmsMenuEdit.themeSrc + "' onclick='cmsMenuEdit.selectEntry(" + index + ")' align='absmiddle' /></span>" + 
      "<span id='cms_item_title_" + index + "' class='cms_ajax_link' onclick='cmsMenuEdit.entryMenu(" + index + ")'>" +
      title + "</span></div>");
      cmsMenuEdit.selectEntry(index);
      $('cms_link_to_url_dest').focus();

      $('cms_create_item').blur();

      cmsMenuEdit.lastIndex++;
      cmsMenuEdit.recreateSortables();
      
  },
  
  unselect: function() {
    if($('cms_item_title_' + cmsMenuEdit.selectedEntry)) {
      $('cms_item_title_' + cmsMenuEdit.selectedEntry).className = 'cms_ajax_link'; 
      cmsMenuEdit.selectedEntry = null;
    }
    $('cms_menu_item_info').style.visibility='hidden';
  },
  
  selectEntry: function(index) {
    var entry = cmsMenuEdit.menuEntries[index];
    cmsMenuEdit.unselect();
    cmsMenuEdit.selectedEntry = index;
    $('cms_item_title_' + index).className = 'cms_ajax_link_selected';
    $('cms_link_to_title').value =entry[0];
    if(entry[1] == 'page') {
      $('cms_link_to_page').checked = true;
      $('cms_link_to_page_dest').value = entry[2];
      $('cms_link_to_url').checked = false;
      $('cms_link_to_url_dest').value = '';
     
     }
     else if(entry[1] == 'url') {
      $('cms_link_to_url').checked = true;
      $('cms_link_to_url_dest').value = entry[2];
      $('cms_link_to_page').checked = false;
      $('cms_link_to_page_dest').value = '';
     }
    setTimeout("$('cms_menu_item_info').style.visibility='visible';",10);
  
  },
  
  saveEntry: function() {
    $('cms_menu_item_info').style.visibility='hidden';
    var dest = $('cms_link_to_page').checked ? 'page' : 'url';
    cmsMenuEdit.updateEntry(cmsMenuEdit.selectedEntry,
                              $('cms_link_to_title').value,
                              dest,
                              dest == 'page' ? $('cms_link_to_page_dest').value : $('cms_link_to_url_dest').value);
    cmsMenuEdit.unselect();
                              
  },
  
  moveKey: function(evt) {
  
    var arrow = SCMS.getArrowKey(evt);
    
    
    if(arrow && cmsMenuEdit.selectedEntry) {
      var entry = cmsMenuEdit.menuEntries[cmsMenuEdit.selectedEntry];
      var elem = $('cms_menu_item_' + cmsMenuEdit.selectedEntry);
      if(arrow == 'up') {
        SCMS.moveElemUp(elem,'cms_menu_item')
      }
      else if(arrow == 'down') {
        SCMS.moveElemDown(elem,'cms_menu_item')
      }
      else if(arrow == 'right' ) {
        entry[3] += 1;
      }
      else if(arrow == 'left' ) {
        if(entry[3] > 1)
          entry[3] -= 1;
      
      }
      cmsMenuEdit.fixLevels();
      return false;
    }
    
    return true;
  
  },
  
  fixLevels: function() {
     var elems = getChildElementsByClass('cms_menu_entries','cms_menu_item');
     var last_entry = null;
     elems.each(function(elem) {
      var entry = cmsMenuEdit.menuEntries[SCMS.getElemNum(elem)];
      
      var previous_level = 0;
      if(last_entry)
        previous_level = last_entry[3];
      
      if(entry[3] > previous_level+1)
        entry[3] = previous_level+1;
      elem.style.paddingLeft = (10 * entry[3]) + "px";
      
      last_entry = entry;
     });
  },
  
  entryMenu: function(index) {
    var opts = new Array(
            ['Delete Menu Item','js','cmsMenuEdit.deleteEntry(' + index + ');' ]
            );
    SCMS.popup(opts);
  },
  
  deleteEntry: function(index) {
    cmsMenuEdit.menuEntries[index] = null;
    Element.remove('cms_menu_item_' + index);
  },
  
  _saveItem: function(i,index) {
    var item = "item[" + i + "]";
    var entry = cmsMenuEdit.menuEntries[index];
    var result = item + "[title]=" + encodeURIComponent(entry[0]) + "&";
    result += item + "[dest]=" + encodeURIComponent(entry[1]) + "&";
    result += item + "[url]=" + encodeURIComponent(entry[2]) + "&";
    result += item + "[level]=" + encodeURIComponent(entry[3]);
    return result;
  },
  
  save: function() {
    var params = '';
    
    Element.show('cms_loading');
    
    var elems = getChildElementsByClass('cms_menu_entries','cms_menu_item');
    for(var i=0;i<elems.length;i++) {
      var entry_index  = SCMS.getElemNum(elems[i]);
      params += cmsMenuEdit._saveItem(i,entry_index) + "&";
    }
    
    new Ajax.Request(cmsEdit.paragraphUrl(cmsMenuEdit.saveUrl,cmsMenuEdit.paragraph_id,cmsMenuEdit.para_index),
                     {
                      parameters: params,
                      onComplete: function(req) {
                        cmsEdit.pageChanged();
                        cmsEdit.closeBox();
                      }
                     });
                
  }
  

};
