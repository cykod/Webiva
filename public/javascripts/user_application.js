SCMS = {

  pickerWin:null,
  pickerOptions:null,

   pickerWindow: function(url,options,params) {
    var screenWidth = 1024, screenHeight = 764;

    params= $H(params);

    if (params.get('scrollbars') == undefined)
      params.set('scrollbars','no')
    if (params.get('resizable') == undefined)
      params.set('resizable','no');

    if (document.all || document.layers) {
      screenWidth = screen.availWidth;
      screenHeight = screen.availHeight;
    }
    var width = params.get('width');
    var height = params.get('height');

    if(!width) {
      width = screenWidth - 20;
    }
    if(!height) {
      height = screenHeight - 20;
    }

    var x = (screenWidth-width)/2;
    var y = (screenHeight-height)/2;
    if(this.pickerWin) {
      this.pickerWin.close();
    }
    this.pickerOptions = options;

    this.pickerWin = window.open(url,"picker",'width=' + width + ',height=' + height + ',toolbar=no,resizable=' + params.get('resizable') + ',scrollbars=' + params.get('scrollbars') + ',top=' + x + ',left=' + y);

    return false;
  },

  pickerCallback: function(val) {
    eval(val);
  },


  updateColorField: function(field) {
    var reg = /^\#([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})([0-9A-Fa-f]{2})$/
    var results = reg.exec($(field).value);
    if(results) {
      $(field + '_color').style.backgroundColor = $(field).value;
      $(field).style.backgroundColor='#FFFFFF';
    }
    else {
      $(field).style.backgroundColor='#FF0000';
    }

  },

  popup: function(links) {
    var txt ='';
    var maxLength=12;
    txt='<div align="left">';

    for(var i=0;i<links.length;i++) {
      var internal = links[i];
      if(internal.length == 3) {
        if(internal[1] == 'js') {
          txt += "<a href='javascript:void(0);' onclick='cClick(); " + internal[2] + "'>" + internal[0] + "</a><br>";
        }
        else {
          txt += "<a href='" + internal[1] + "'onclick='nd(); return confirm(\"" + internal[2] + "\");' >"  + internal[0] + "</a><br>";
        }
        if(internal[0].length > maxLength)
          maxLength=internal[0].length;

      }
      else if(internal.length == 2) {
          txt += "<a href='" + internal[1] + "'>" + internal[0] + "</a><br>";
          if(internal[0].length > maxLength)
            maxLength=internal[0].length;
      }
      else if(internal.length == 0 && (links.length-1) != i) {
        txt += "<hr>";
      }
    }
    txt +=" </div>"
    var width=30+maxLength * 7;

    performActionText = "Action"

    overlib(txt,CAPTION,"&nbsp;" + performActionText,STICKY,RIGHT,OFFSETX,0,OFFSETY,12,WIDTH,width,
          FGCOLOR,'#FFFFFF',BGCOLOR,'#bababa',CLOSETEXT,"<img src='/images/site/close.gif' border='0' />");


  },

  close_overlay: function() {
    RedBox.close();
  },

  overlay: function(text) {
    var nd = $('SCMS_overlay_hidden');
    if(!nd) {
      nd = Builder.node('div', { id: 'SCMS_overlay_hidden', style: 'display:none;' });
      var body = document.getElementsByTagName('body');
      body[0].appendChild(nd);
    }
    nd.innerHTML = text;

    RedBox.showOverlay();
    RedBox.addHiddenContent('SCMS_overlay_hidden');
  },



	show_hide: function(show,hide,swap) {
	  if(swap) {
		  Element.hide(show);
		  Element.show(hide);
	  }
	  else {
	    Element.show(show);
	    Element.hide(hide);
	  }
	},

	showHide: function(show,hide,swap) {
	  if(swap) {
		  Element.hide(show);
		  Element.show(hide);
	  }
	  else {
	    Element.show(show);
	    Element.hide(hide);
	  }
	},

 updateOverlay: function(url,params) {
    if(!params) {
      params = {};
    }
    new Ajax.Request(url,
              { parameters: params,
               onComplete: function(req) {
                   var contentType = req.getHeader('Content-type');
                   if(!(contentType && contentType.match(/^\s*(text|application)\/(x-)?(java|ecma)script(;.*)?\s*$/i))) {
                      SCMS.overlay(req.responseText);
                      req.responseText.evalScripts();
                   }
                  $('RB_overlay').onclick = function() { RedBox.close(); if($('RB_window'))  $('RB_window').innerHTML = ''; }
              }});
  },

  remoteOverlay: function(url,params) {
    RedBox.loading();
    if($("RB_window")) {
      return SCMS.updateOverlay(url,params);
    }
    if(!params) {
      params = {};
    }
    new Ajax.Request(url,
              { parameters: params,
               onComplete: function(req) {
                  SCMS.overlay(req.responseText);
                  req.responseText.evalScripts();
                  $('RB_overlay').onclick = function() { RedBox.close(); if($('RB_window')) $('RB_window').innerHTML = ''; }
              }});

  },



  closeOverlay: function() {
    RedBox.close();
  },

   openWindow: function(url,name,width,height,resizable,scrollbars) {
      var screenWidth = 1024, screenHeight = 764;

      if (scrollbars == null) scrollbars = 'yes';
      if (resizable== null) resizable= 'yes';

      if (document.all || document.layers) {
        screenWidth = screen.availWidth;
        screenHeight = screen.availHeight;
      }

      if(!width) {
        width = screenWidth - 20;
      }
      if(!height) {
        height = screenHeight - 20;
      }

      var x = (screenWidth-width)/2;
      var y = (screenHeight-height)/2;
      var opts = 'width=' + width + ',height=' + height + ',toolbar=no,resizable=' + resizable +",scrollbars=" + scrollbars + ',top=' + x + ',left=' + y;

      var win = window.open(url,name,opts);
      return false;
  },

   highlightRow: function(row) {
      $(row).addClassName('highlighted_row');
  },

  lowlightRow: function(row,callback) {
      $(row).removeClassName('highlighted_row');

      if(callback == undefined)
        callback = '';
  },

  clickRow: function(elem_type,elem_id) {

      if($('elem_' + elem_type + '_' + elem_id)) {
        $('elem_' + elem_type + '_' + elem_id).checked = !$('elem_' + elem_type + '_' + elem_id).checked;
      }

      var row=$('elem_' + elem_type + '_' + elem_id + '_row')

      if($('elem_' + elem_type + '_' + elem_id)) {
        if($('elem_' + elem_type + '_' + elem_id).checked)
          row.addClassName('selected_row');
        else
          row.removeClassName('selected_row');
      }


  },

  getElemNum: function(elem) {
    elem = $(elem);
    var elem_id = elem.id.split("_");
    elem_id = elem_id[elem_id.length - 1];

    return Number(elem_id);

  },

  elemNumArray: function(container,className) {
    container = $(container);

    var elems= $A(document.getElementsByClassName(className,container));

    var selectedIds = [];
    elems.each(function(elem) {
	selectedIds.push(SCMS.getElemNum(elem.id));
    })

    return selectedIds;

  },

  toggleDiv: function(elem) {
    elem = $(elem);
    if(elem.style.display == 'none')
      Element.show(elem);
    else
      Element.hide(elem);
	}





};

