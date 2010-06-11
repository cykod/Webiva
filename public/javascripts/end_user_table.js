var EndUserTable = {


  tables: {},
  
  registerTable: function(table_name,url,update_div) {
    EndUserTable.tables[table_name] = [ url,update_div];
  
  },
  
  order: function(table_name,column_name) {
    var params = table_name + "[order]=" + encodeURIComponent(column_name);
    EndUserTable.update(table_name,params);
  }, 
  
  update:function(table_name,parameters) {
    if(!parameters) {
      $(table_name + '_table_action').value = '';
      var form = $(table_name + '_update_form');
      parameters = Form.serialize(form)

    }
    tbl = EndUserTable.tables[table_name];
    new Ajax.Updater(tbl[1],tbl[0], {
          parameters: parameters,
          evalScripts:true });
  
  },
  
  page: function(table_name,page) {
    var params = table_name + "[page]=" + encodeURIComponent(page);
    EndUserTable.update(table_name,params);
  },
  
  refresh:function(table_name) {
    EndUserTable.update(table_name,''); 
  },
  
  checkAll: function(table_name,check) {
     var elements = $(table_name + '_update_form').getInputs();
     elements.each(function(elem) {
       if(elem.type == 'checkbox' && elem.className == 'entry_checkbox')
        elem.checked = check
        if($(elem.id + "_row"))
          check ? $(elem.id + "_row").addClassName('selected_row') :  $(elem.id + "_row").removeClassName('selected_row') 
     });
    
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
     elements.each(function(elem) {
       if(elem.type == 'checkbox' && elem.className == 'entry_checkbox' && elem.checked)
        count++;
     });
    return count;
  },  
  
 action: function(table_name,action,confirmed,extra_params) {
    if(this.countChecked(table_name) > 0) {
      if(!confirmed || confirm(confirmed)) {
        $(table_name + '_table_action').value = action;
        
        var form = $(table_name + '_update_form');
        var params = Form.serialize(form)
        if(extra_params) {
          params += "&" + extra_params;
        }        
        this.update(table_name,params);
      }
    }

  }


};
