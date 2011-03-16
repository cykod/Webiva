/* Make this JS library independant during the jquery transition */

ActiveTable = function() {
 var $ = function(e) { return document.getElementById(e); } ;
 var each = function(collection,callback) {
   var cnt = collection.length;
   for(i = 0;i < cnt;i++) {
     callback.call(this,collection[i]);
   }
 };
 return {
  header: function(table_name,field) {
  
    var value_elem = $(table_name + '_' + field + '_searching');
    var sel_elem = $(table_name + '_' + field + '_search_for');

    
    var elems = $(table_name + "_search_form").select('span');
    var search_count = new Number($(table_name + '_search_cnt').value);
    each(elems,function(elm) {
      if(sel_elem == elm) {
        value_elem.value = '1';
        
        $(table_name + '_search').style.display='';
        $(table_name + '_search_fields').style.display='';
         if($(table_name + '_' + field)) {
            if($(table_name + '_' + field).type == 'text') {
                $(table_name + '_' + field).focus();
            }
         }
        $(table_name + '_search_cnt').value = search_count + 1;
      }
      else {
        elm.style.display='none';
      }

    });
    sel_elem.style.display='';

  },

  checkAll: function(table_name,check) {
     var elements = $(table_name + '_update_form').getInputs();
     each(elements,function(elem) {
       if(elem.type == 'checkbox' && elem.className == 'entry_checkbox')
        elem.checked = check
        if($(elem.id + "_row"))
          check ? $(elem.id + "_row").addClassName('selected_row') :  $(elem.id + "_row").removeClassName('selected_row') 
     });
    
    },
  
  refresh: function(table_name,url,update_element,extra_params) {
    this.highlight(table_name);
    var form = $(table_name + '_update_form');
    var params = Form.serialize(form)
    if(extra_params) {
      if(!Object.isString(extra_params)) {
        extra_params = Object.toQueryString(extra_params);
      }
      params += "&" + extra_params;
    }
    if(update_element) 
      new Ajax.Updater(update_element,url,{ parameters: params, evalScripts: true });
    else
      new Ajax.Request(url,{ parameters: params, evalScripts: true });

    return false;
  
  },

  perPageSize: function(size,table_name,url,update_element) {
    $(table_name + '_per_page').value = size;
    $(table_name + '_page').value = 1;
    this.refresh(table_name,url,update_element);
    return false;
  },

  countChecked: function(table_name) {
    var count=0;
    var elements = $(table_name + '_update_form').getInputs();
     each(elements,function(elem) {
       if(elem.type == 'checkbox' && elem.className == 'entry_checkbox' && elem.checked)
        count++;
     });
    return count;
  },

  windowPopup: function(total_count,table_name,url,update_element) {
    var nums = $A([ 5,10,25,50,100,250,500 ])
    var arr = [];
    last = 1;
    each(nums,function(num) {
        if(num < 10 || num < total_count || last) {
           if(num > total_count) {
              arr.push(["Show all","js","ActiveTable.perPageSize(" + num + ",'" + table_name + "','" + url + "','"  + update_element + "');"]);
              last = 0;
           } 
           else {
             arr.push([num + " per page","js","ActiveTable.perPageSize(" + num + ",'" + table_name + "','" + url + "','"  + update_element + "');"]);
           }
        }
    });
    SCMS.popup(arr, { location: "above", action: 'Show' });

  },

  

  action: function(action,confirmed,table_name,url,update_element,extra_params) {
    if(this.countChecked(table_name) > 0) {
      if(!confirmed || confirm(confirmed)) {
        $(table_name + '_table_action').value = action;
        this.refresh(table_name,url,update_element,extra_params);
      }
    }

  },
  
  clearSearch: function(table_name,url,update_element) {
    var params = table_name + '[clear_search]=1'
    if(update_element) 
      new Ajax.Updater(update_element,url,{ parameters: params, evalScripts: true });
    else
      new Ajax.Request(url,{ parameters: params, evalScripts: true });

    return false;
  
  },

  clearSearchField: function(update_element,url,table_name,field) {

    var value_elem = $(table_name + '_' + field + '_searching');
    var sel_elem = $(table_name + '_' + field + '_search_for');

    value_elem.value = '0';
    ActiveTable.refresh(table_name,url,update_element);
  
  },
  
  page: function(page,table_name,url,update_element) {
    this.highlight(table_name);

    if(update_element) 
      new Ajax.Updater(update_element,url,{ parameters: 'page=' + page, evalScripts: true });
    else
      new Ajax.Request(url,{ parameters: 'page=' + page, evalScripts: true });

    return false;
  },
  
  checkOne: function(field_name,checked_id) {
    var i = 0;
    while($(field_name + '_' + i)) {
        $(field_name + '_' + i).checked = (i == checked_id) ? true : false;
        i++;
    }
  },
  
  order: function(update_element,url,table_name,field) {
    this.highlight(table_name);
    
    if(update_element) 
        new Ajax.Updater(update_element,url,{ parameters: 'order=' + field, evalScripts: true });
      else
        new Ajax.Request(url,{ parameters: 'order=' + field, evalScripts: true });
    return false;
  },

  highlight: function(table_name) {
    var tables = $(table_name + "_update_form").select('table');
    tables[0].addClassName('table_highlight');

  }
  } 
  
}();
