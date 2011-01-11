SCMS = {

	popup: function(links,options) {
		var txt ='';
		var maxLength=12;
		for(var i=0;i<links.length;i++) {
			var internal = links[i];
			if(internal.length == 3) {
				if(internal[1] == 'js') {
					txt += "<a href='javascript:void(0);' onclick='cClick(); " + internal[2].replace(/\'/g,"&apos;") + "'>" + internal[0] + "</a>";
				}
				else {
					txt += "<a href='" + internal[1] + "'onclick='nd(); return confirm(\"" + internal[2].replace(/\'/g,"&apos;").replace(/\'/g,"&quot;") + "\");' >"  + internal[0] + "</a>";
				}
				if(internal[0].length > maxLength)
					maxLength=internal[0].length;

			}
			else if(internal.length == 2) {
					txt += "<a href='" + internal[1] + "'>" + internal[0] + "</a>";
					if(internal[0].length > maxLength)
						maxLength=internal[0].length;
			}
			else if(internal.length == 0 && (links.length-1) != i) {
				txt += "<hr>";
			}
		}

		var width=30+maxLength * 7;

                if(!options) {
                    options={};
                }

                var performActionText = options['action'] ? options['action'] : "Action"

                var loc;

                if(options['location']) {
                 loc = options['location'] == 'below' ? BELOW : ABOVE;
                }
                else loc = BELOW;

		overlib(txt,CAPTION,"&nbsp;" + performActionText,STICKY,loc,OFFSETX,0,OFFSETY,12,WIDTH,width,
                             FGCLASS,'cms_popup_text',BGCLASS,'cms_popup_bg',CAPTIONFONTCLASS,'cms_popup_caption',
		                      MOUSEOFF,CLOSETEXT,'');
                /* FGCOLOR,'#FFFFFF',BGCOLOR,'#bababa',CLOSETEXT,'<img src="/images/site/close_gray.gif" width="16" height="16" border="0"/>');*/


	},

	customPopup: function(txt,title) {
	 var performActionText = title ? title : "Action"

	overlib(txt,CAPTION,"&nbsp;" + performActionText, STICKY,BELOW,OFFSETX,0,OFFSETY,12,WIDTH,340,
                             FGCLASS,'cms_popup_text',BGCLASS,'cms_popup_bg',CAPTIONFONTCLASS,'cms_popup_caption',
		                      MOUSEOFF,CLOSETEXT,'');

	},

	show_hide: function(show,hide) {
		Element.show(show);
		Element.hide(hide);
	},

	showHide: function(show,hide,swap) {
	  if(!swap) {
		  Element.show(show);
		  Element.hide(hide);
	  }
	  else {
  		Element.hide(show);
		  Element.show(hide);
	  }
	},

	toggle: function(elems,visibility) {
	  for(var i=0;i<elems.length;i++) {
	    if(visibility[i]) {
	      Element.show(elems[i]);
	    }
	    else {
	      Element.hide(elems[i]);
	    }
	  }
	},

	enable_disable: function(enable,disable) {

		$(enable).disabled = false;
		$(disable).disabled = true;
	},

	get_file_extension: function(filename) {
		var period = filename.lastIndexOf(".");
		if(period== -1) return "";
		return filename.substr(period,filename.length);

	},


	select_tab_num: function(num) {
	  var elem = document.getElementsByClassName('ajax_link')[num-1]
	  if(elem)
  	  SCMS.select_tab(elem);
	},


	select_tab: function(elem) {
		var selected_td = elem.parentNode;
		var row = selected_td.parentNode;
		var tbody = row.parentNode;

		var tabs = row ? getChildElements(row) : []; // 0, T1-Tn, Extra
		var contents = tbody ? getChildElements(tbody) : []; // Header, T1-Tn

		var i=0;
		for(i=1;i<contents.length;i++) {
			Element.hide(contents[i]);
		}
		for(i=1;i<tabs.length;i++) {
			if(tabs[i-1] != selected_td) {
				tabs[i-1].className = 'normal';

			}
			else {
				tabs[i-1].className = 'selected';
                                if(contents.length > i ) {
                                  Element.show(contents[i]);
                                }
			}

		}
	},


	setFileField: function(field,file_type,file_id,file_name,file_url,file_thumb) {
	  if(file_name) {
  		$(field + '_name').innerHTML = file_name;
  	} else {
  		$(field + '_name').innerHTML = 'Select File';
  	}
    if(file_type == 'img' && $(field + '_thumb'))  $(field + '_thumb').src = file_thumb;
		$(field).value = file_id;
    if($(field).onchange)
      $(field).onchange();



	},

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




  moveElemUp: function(elem,cls) {
    elem = $(elem);
    var previousElem = SCMS.elemBefore(elem,cls);

    var parentContainer = elem.parentNode;
    if(previousElem) {
      Element.remove(elem);
      parentContainer.insertBefore(elem,previousElem);
      return true;
    }
    else {
      return false;
    }

  },

  moveElemDown: function(elem,cls) {
    elem = $(elem);

    // Get the parent of the elem
    // If we're not the first one
    var parentContainer = elem.parentNode;
    var elems = (cls != undefined) ? getChildElementsByClass(parentContainer,cls) : getChildElements(parentContainer);

    var nextElemAfter = null;
    var nextElem = null;
    for(var i=elems.length-1;i>=0;i--) {
      if(elems[i] == elem)
      break;
      nextElemAfter = nextElem;
      nextElem = elems[i];
    }

    if(nextElemAfter) {
      Element.remove(elem);
      parentContainer.insertBefore(elem,nextElemAfter);
      return true;
    }
    else if(nextElem) {
      Element.remove(elem);
      parentContainer.appendChild(elem);
      return true;
    }
    else {
      return false;
    }

  },

  elemBefore: function(elem,cls) {
    elem = $(elem);

   // Get the parent of the elem
    // If we're not the first one
    var parentContainer = elem.parentNode;


    var elems = (cls != undefined) ? getChildElementsByClass(parentContainer,cls) : getChildElements(parentContainer);

    var previousElem = null;
    for(var i=0;i<elems.length;i++) {
      if(elems[i] == elem)
      break;
      previousElem = elems[i];
    }

    if(previousElem)
      return previousElem;
    else
      return false;
  },

  elemAfter: function(elem, cls) {

    elem = $(elem);

    // Get the parent of the elem
    // If we're not the first one
    var parentContainer = elem.parentNode;
    var elems = (cls != undefined) ? getChildElementsByClass(parentContainer,cls) : getChildElements(parentContainer);

    var nextElem = null;
    for(var i=elems.length-1;i>=0;i--) {
      if(elems[i] == elem)
      break;
      nextElem = elems[i];
    }

    if(nextElem) {
      return nextElem;
    }
    else {
      return false;
    }
   },

  elemPosition: function(elem,cls) {
    elem = $(elem);

    var parentContainer = elem.parentNode;
    var elems = (cls != undefined) ? getChildElementsByClass(parentContainer,cls) : getChildElements(parentContainer);

    for(var i=0;i<elems.length;i++) {
      if(elems[i] == elem)
        return i;
    }
    return -1;
  },

  unshiftElem: function(parent,elem,cls) {

    var elems = (cls != undefined) ? getChildElementsByClass(parent,cls) : getChildElements(parent);
    if(elems.length == 0) {
      parent.appendChild(elem);
    }
    else {
      parent.insertBefore(elem,elems[0]);
    }

    return true;
  },

  popupDiv: function(elem)  {
    elem = $(elem);
    SCMS.hideSelectBoxes();

    elem.onmouseover=SCMS.popupDiv_show;
    elem.onmouseout=SCMS.popupDiv_delayedHide;
    Element.show(elem);
  },

  hidePopupDiv: function(elem) {
    SCMS.popupDiv_delayedHideExecute($(elem).id);
  },


  popupDiv_delayedHide: function () {
    var elem = this;
    if(!elem.delayedTimer)  {
      elem.delayedTimer = setTimeout("SCMS.popupDiv_delayedHideExecute('" + elem.id + "');",100);
    }
  },

  popupDiv_delayedHideExecute: function(elem_id) {
    var elem = $(elem_id);
    if(elem) {
      if(elem.delayedTimer)
        clearTimeout(elem.delayedTimer);
      Element.hide(elem);
      SCMS.showSelectBoxes();
   }
  },

  popupDiv_show: function() {
    var elem = this;
    if(elem.delayedTimer) {
      clearTimeout(elem.delayedTimer);
      elem.delayedTimer = null;
    }

  },

  showSelectBoxes: function(){
    if(document.all) {
      selects = document.getElementsByTagName("select");
      for (i = 0; i != selects.length; i++) {
        selects[i].style.visibility = "visible";
      }
    }
  },


  hideSelectBoxes: function(){
    if(document.all) {
      selects = document.getElementsByTagName("select");
      for (i = 0; i != selects.length; i++) {
        selects[i].style.visibility = "hidden";
      }
    }
  },

  setKeyHandler: function(func) {
    if(document.all) {
      document.onkeydown = func;
    }
    else {
      document.onkeypress = func;
    }
  },

  getEscapeKey: function(evt) {

    evt = (evt) ? evt : ((window.event) ? event : null);
    var charCode = (evt.charCode) ? evt.charCode :
        ((evt.which) ? evt.which : evt.keyCode);
    var Esc = (window.event) ?  27 : evt.DOM_VK_ESCAPE; // MSIE : Firefox

    if(charCode == Esc)
      return true;
    else
      return false;
  },

  isEnter: function(evt) {

    evt = (evt) ? evt : ((window.event) ? event : null);
    var charCode = (evt.charCode) ? evt.charCode :
        ((evt.which) ? evt.which : evt.keyCode);
    var Ent = (window.event) ?  14 : evt.DOM_VK_ENTER; // MSIE : Firefox
    var Ret = (window.event) ?  13 : evt.DOM_VK_RETURN; // MSIE : Firefox

    if(charCode == Ent || charCode == Ret)
      return true;
    else
      return false;

  },

  getArrowKey: function(evt) {

    evt = (evt) ? evt : ((window.event) ? event : null);
    var charCode = (evt.charCode) ? evt.charCode :
        ((evt.which) ? evt.which : evt.keyCode);

    var ArrowUpKey = (window.event) ?
            38 : evt.DOM_VK_UP ;// MSIE : Firefox
    var ArrowDownKey = (window.event) ?
            40 : evt.DOM_VK_DOWN ;// MSIE : Firefox
    var ArrowRightKey = (window.event) ?
            39 : evt.DOM_VK_RIGHT ;// MSIE : Firefox
    var ArrowLeftKey = (window.event) ?
            37 : evt.DOM_VK_LEFT ;// MSIE : Firefox
    if(charCode == ArrowUpKey)
      return 'up';
    else if(charCode == ArrowDownKey)
      return 'down';
    else if(charCode == ArrowRightKey)
      return 'right';
    else if(charCode == ArrowLeftKey)
      return 'left';
    else return null;
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

  closeOverlay: function() {
    RedBox.close();
  },



  remoteOverlay: function(url,params,method) {
    RedBox.loading();
    if(!method) method='post';
    if(!params) {
      params = {};
    }

    new Ajax.Request(url,
              { parameters: params,
                method: method,
               onComplete: function(req) {
                  SCMS.overlay(req.responseText);
                  req.responseText.evalScripts();
              }});

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
              }});
  },

  imageOverlay: function(url,width,height) {
    //RedBox.loading();
    RedBox.showOverlay();

    var nd = $('SCMS_overlay_hidden');
    if(!nd) {
      nd = Builder.node('div', { id: 'SCMS_overlay_hidden', style: 'display:none;' });
      var body = document.getElementsByTagName('body');
      body[0].appendChild(nd);
    }

    $('SCMS_overlay_hidden').innerHTML='';

    var container = Builder.node('div', { style: 'padding:20px;' });
    var actions = Builder.node('div');
    actions.innerHTML = "<a href='javascript:void(0);' onclick='RedBox.close();'>Close</a>";

    var image = document.createElement("img");
    image.id='overlay_image';
    SCMS._imageDisplay(image,width,height)
    image.setAttribute('src',url);

    container.appendChild(image);
    container.appendChild(actions);

    nd.appendChild(container);

    setTimeout("RedBox.addHiddenContent('SCMS_overlay_hidden');",10);
  },

  _imageDisplay: function(image,width,height) {
    var pageSize = RedBox.getPageSize();

    var orig_width = width;
    var orig_height =height;

    var horiz_scale = (pageSize[0] - 200) / width;
    var vert_scale = (pageSize[1] - 200) / height;

    var scale = horiz_scale < vert_scale ? horiz_scale : vert_scale;

    var scaleFactor = 100;
    if(scale > 1.0) {
      scale = 1.0;
    }
    var img_width = width * scale;
    var img_height= height * scale;
    image.width = img_width;
    image.height = img_height;
    image.style.width=img_width+ "px";
    image.style.height=img_height+ "px";

    scaleFactor = Math.round(scale * 100);

    new Insertion.Top('SCMS_overlay_hidden',"&nbsp; " + orig_width + "px X " + orig_height + "px (" + scaleFactor + "%)");

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

  emptyQueue: function(scope) {
    var queue = Effect.Queues.get(scope);
    queue.each(function(e) { e.cancel() });

  },

  setCookie: function(name, value, expires, path, domain, secure) {
      var curCookie = name + "=" + escape(value) +
      ((expires) ? "; expires=" + expires.toGMTString() : "") +
      ((path) ? "; path=" + path : "") +
      ((domain) ? "; domain=" + domain : "") +
      ((secure) ? "; secure" : "");
     document.cookie = curCookie;
  },

  getCookie: function(name) {
    var dc = document.cookie;
    var prefix = name + "=";
    var begin = dc.indexOf("; " + prefix);
    if (begin == -1) {
      begin = dc.indexOf(prefix);
      if (begin != 0) return null;
    } else
      begin += 2;
    var end = document.cookie.indexOf(";", begin);
    if (end == -1)
      end = dc.length;

    return unescape(dc.substring(begin + prefix.length, end));
  },

  deleteCookie: function(name, path, domain) {
    if (getCookie(name)) {
      document.cookie = name + "=" +
      ((path) ? "; path=" + path : "") +
      ((domain) ? "; domain=" + domain : "") +
      "; expires=Thu, 01-Jan-70 00:00:01 GMT";
    }
  }


}


function showMenu(id) {
  if($(id)) {
    clearTimeout($(id).timer);
    $(id).timer = null;
  }


}
function clearMenu(id) {
  $(id).timer = null;
  Element.remove(id);

}

function hideMenu(id) {
  $(id).timer = setTimeout("clearMenu('" + id + "')",200);
}

function getChild(parentElement,className) {
  var children = getChildElementsByClass(parentElement,className);

  if(children.length > 0)
    return children[0];
  else
    return null;
}

function getChildElementsByClass(parentElement,className) {
  parentElement = $(parentElement);
  var nodes = parentElement.childNodes;

  var children = new Array();
  for(var i=0;i<nodes.length;i++) {
    if(nodes[i].nodeType == 1) {
      if(nodes[i].className == className) {
        children.push($(nodes[i]));
      }
    }
  }

  return $A(children);
}

function getChildElements(parentElement) {
  var nodes = parentElement.childNodes;

  var children = new Array();
  for(var i=0;i<nodes.length;i++) {
    if(nodes[i].nodeType == 1)
      children.push($(nodes[i]));
  }

  return $A(children);
}

function delayedHide(elem) {
  if(!elem.delayedTimer)  {
    elem.delayedTimer = setTimeout("delayedHideExecute('" + elem.id + "');",100);
  }

}

function delayedHideShow(elem) {
  if(elem.delayedTimer) {
    clearTimeout(elem.delayedTimer);
    elem.delayedTimer = null;
  }
}

function delayedHideExecute(elem_id) {
    if($(elem_id)) {
      clearTimeout($(elem_id).delayedTimer);
      Element.hide(elem_id);
   }
}

function displayDropdown(elem_id) {
  var base_elem = $(elem_id);
  Element.toggle(base_elem);

}

function selectDropdownElement(selected_elem) {

      elems = getChildElements(selected_elem.parentNode);
      elems.each(function(elem) {
          Element.removeClassName(elem,'cms_dropdown_selected');
        });

      var selectedItem = getChild(selected_elem.parentNode.parentNode,'cms_dropdown_display');
      if(selectedItem) {
        selectedItem.innerHTML = selected_elem.innerHTML;
        Element.addClassName(selected_elem,'cms_dropdown_selected');
      }
}

function isdefined( variable)
{
    return (typeof(window[variable]) == "undefined")?  false: true;
}


function includeJS(path,onComplete) {
  var e = document.createElement("script");
  e.setAttribute('src',path);
  e.setAttribute('type',"text/javascript");
  e.setAttribute('charset','utf-8');

  if(document.all) {
    e.onreadystatechange = function() {
      if(e.readyState=="complete" || e.readyState=="loaded") {
        onComplete();
      }
    }
  }
  else {
    e.onload = onComplete;
  }

  document.getElementsByTagName("head")[0].appendChild(e);

  return false;
}



function showSelectBoxes(){
	selects = document.getElementsByTagName("select");
	for (i = 0; i != selects.length; i++) {
		selects[i].style.visibility = "visible";
	}
}


function hideSelectBoxes(){
	selects = document.getElementsByTagName("select");
	for (i = 0; i != selects.length; i++) {
		selects[i].style.visibility = "hidden";
	}
}

function hashChildQueryString(hsh,elem) {
   return hsh.map(function(pair) {
      return elem + '[' +  encodeURIComponent(pair[0]) + ']=' + encodeURIComponent(pair[1])
    }).join('&');
}


function openWindow(url,name,width,height,resizable,scrollbars) {
  var screenWidth = 1024, screenHeight = 764;

  if (scrollbars == null) scrollbars = 'no';
  if (resizable== null) resizable= 'no';

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
//  alert(opts);
  return win;
}

function mceResizeCallback(e) {
   mceResizeEditorBox(tinyMCE.activeEditor);
}

/* Src: http://wiki.moxiecode.com/index.php/TinyMCE:Auto_resize_editor_box */
function mceResizeEditorBox(editor) {
    // Have this function executed via TinyMCE's init_instance_callback option!
    // requires TinyMCE3.x

//    var formObj = document.forms[1], // this might need some adaptation to your site

   var container = editor.contentAreaContainer; /* new in TinyMCE3.x -for TinyMCE2.x you need to retrieve the element differently! */
   var docFrame = container.children[0];
  var doc,docHeight;

   if (docFrame.contentDocument) doc = docFrame.contentDocument;
   else if (docFrame.contentWindow) doc = docFrame.contentWindow.document;
   else if (docFrame.document) doc = docFrame.document;

  doc.body.style.overflow = "hidden";

    //Firefox
  if ( doc.height ) docHeight = doc.height;
  //MSIE
  else docHeight = parseInt(doc.body.scrollHeight);

  docHeight+=10;

  if(docHeight < 100) docHeight = 100;
  docFrame.style.height = container.style.height = (docHeight) + "px";
}


  // Authenticity token hack
try {
if (!AUTH_TOKEN)
   AUTH_TOKEN = 'DummyToken';
}
catch (e)
{
 AUTH_TOKEN = 'DummyToken';
}

// A Little hacky
Object.toQueryString = function (object) {
                 var result =  $H(object).toQueryString();
                 if (!result.include ("authenticity_token"))
                 {
                   result += "&authenticity_token=" + encodeURIComponent (AUTH_TOKEN);
                 }
                 return result;
               };

if(typeof JQuery != 'undefined') {
  jQuery(document).ajaxSend(function(event, request, settings) {
    if(typeof(AUTH_TOKEN) == "undefined") return;
    // settings.data is a serialized string like "foo=bar&baz=boink" (or null)
    settings.data = settings.data || "";
    settings.data += (settings.data ? "&" : "") + "authenticity_token=" + encodeURIComponent(AUTH_TOKEN);
  });
}
