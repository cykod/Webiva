function mceSetupContent(ed) {
  var toolbar = $$('.mceExternalToolbar')[0];
  toolbar.removeClassName('mceExternalToolbar');
  toolbar.addClassName('cms_html_editor_toolbar');
  toolbar.addClassName('defaultSkin');
  toolbar.style.visibility = 'visible';
  toolbar.style.display = 'block';
  toolbar.select('table')[0].style.margin ='0 auto';
  toolbar.style.top = '0px';
  toolbar.parentNode.removeChild(toolbar);
  $('cms_html_toolbar').appendChild(toolbar);
  Element.hide(toolbar);

}



var cmsSkipCommands = { mceAddUndoLevel: true,
                        mceInsertAnchor: true,
                        mceAdvLink: true,
                        cmsFileManager: true,
                        mceInsertTable: true,
                        mceCodeEditor: true
                        }

function mceExecCallback(editor_id, elm, command, user_interface, value) {
  if(cmsEdit.pageModified == false) {
    if(!cmsSkipCommands[command])  {
      cmsEdit.pageChanged();
    }
  }
  return false;
}

var cmsSkipKeys ={ 37:true,38:true,39:true,40:true,33:true,34:true,16:true,144:true,36:true,45:true,35:true,17:true,18:true };


function mceEventCallback(e) {
  var active_instance_id = tinyMCE.selectedInstance ? tinyMCE.selectedInstance.editorId : "";
  if(cmsEdit.visibleHtmlToolbar != active_instance_id ) {
    if(e.type != 'blur') {
      cmsEdit.showToolbar(active_instance_id);
    } else {
      cmsEdit.hideToolbars();
    }
  }
  if(e && cmsEdit.pageModified == false) {
    var re = /^mouse(.*)$/
    if(e.type != 'focus' && e.type != 'blur' && e.type != 'click' && e.type != 'keypress' && e.type != 'keyup' && !re.exec(e.type)) {
      if(e.type == 'keydown') {

        var charCode = (e.charCode) ? e.charCode :
				((e.which) ? e.which : e.keyCode);
        if(!cmsSkipKeys[charCode])
	   cmsEdit.pageChanged();
      }
      else {
        cmsEdit.pageChanged();
      }
    }

  }

  if(e.type =='focus') {
     cmsEdit.unselectParagraph();
  }
  //mceResizeEditorBox(tinyMCE.activeEditor);
  //tinyMCE.selectedInstance.resizeToContent();
  return true;
}

function mceInitInstance(editor) {
  //editor.resizeToContent();
 // mceResizeEditorBox(editor);

}


var cmsEdit = {
  editURL: null,
  previousPageType:null,
  previousPageId:null,
  pageType: null,
  pageId: null,
  revisionId: null,
  siteTemplateId:null,
  pageActive: false,
  availableParagraphs:null,
  language: null,
  paraIndex:0,

  destPageId:null,
  destRevisionId:null,
  destParams:null,

  addParagraphType:null,
  addParagraphPub:null,

  visibleHtmlToolbar:null,
  pageModified:false,

  features:{},
  focusedElem:null,
  selectedParagraph:null,
  updateParagraphs:null,
  paragraphs:$H({}),

  setEditURL: function(url) {
    cmsEdit.editURL = url;
  },

  setPageInfo: function(page_type,page_id,revision_id,lang,active,template_id,page_url)  {
    if((cmsEdit.previousPageType != page_type) || (cmsEdit.previousPageId != page_id)) {
        cmsEdit.pageUrl = page_url;

      if(cmsEdit.pageUrl == 'Domain') cmsEdit.pageUrl = '/';
    }
    cmsEdit.pageType= page_type;
    cmsEdit.pageId = page_id;
    cmsEdit.revisionId = revision_id;
    cmsEdit.language = lang;
    cmsEdit.pageActive = active;
    if(template_id) {
      cmsEdit.siteTemplateId = template_id;
    }
    cmsEdit.previousPageType = page_type;
    cmsEdit.previousPageId = page_id;
    $('cms_goto_page').href = cmsEdit.pageUrl;
  },

  setParagraphIndex: function(para_index) {
    cmsEdit.paraIndex = para_index;
  },

  setText: function(txt) {
    cmsEdit.txt = $H(txt);
  },

  showToolbar: function(active_instance_id) {
    var toolbars = $$('.cms_html_editor_toolbar');
    for(var i=0;i<toolbars.length;i++) {
      if(toolbars[i].id == active_instance_id + "_external") {
        toolbars[i].style.display = "block";
      }
      else
        Element.hide(toolbars[i]);
    }
    cmsEdit.visibleHtmlToolbar  = active_instance_id;


  },

  hideToolbars: function() {
    var toolbars = $$('.cms_html_editor_toolbar');
    cmsEdit.visibleHtmlToolbar  = null;
    for(i=0;i<toolbars.length;i++) {
       Element.hide(toolbars[i]);
    }
  },

  prepareUpdate: function() { cmsEdit.updateParagraphs = {}; },
  updateParagraphId: function(old_paragraph_id,new_paragraph_id) { cmsEdit.updateParagraphs['' + old_paragraph_id] = new_paragraph_id },
  handleUpdate: function() {
    cmsEdit.paragraphs.each(function(elem) {
      var para=elem[1];
      if(para) {
        var updatePara = cmsEdit.updateParagraphs['' + para.paragraph_id];
        para.paragraph_id = updatePara;
      }

    });
  },

	setParagraphs: function(paras) {
		cmsEdit.availableParagraphs = $H(paras);
	},

	clearTemplateFeatures: function() {
	  cmsEdit.features = {};

	},

  setTemplateFeatures: function(template_id,feature_type,feature_list) {
    if(!cmsEdit.features[template_id]) {
      cmsEdit.features[template_id] = $H({ def: [] } );
    }

    cmsEdit.features[template_id].set(feature_type,feature_list);

  },

  getFeatures: function(template_id,feature_type) {
    var tpl_features = cmsEdit.features[template_id];
    var all_features = cmsEdit.features[0];

    var feat = []



    if (tpl_features &&  tpl_features.get(feature_type)) feat = feat.concat(tpl_features.get(feature_type));
    if (all_features && all_features.get(feature_type)) feat = feat.concat(all_features.get(feature_type));
    return feat;
  },

	url: function(action) {
	    return  cmsEdit.editURL + action + "/" + cmsEdit.pageType  + "/" + cmsEdit.pageId + "/" + cmsEdit.revisionId;
  	},

	templateUrl: function(action,item_id) {
	    if(item_id) {
  	    return  '/website/templates/' + action + "/" + item_id
  	  }
  	  else {
  	    return  '/website/templates/' + action
  	  }
  	},


  paragraphUrl: function(url,paragraph_id,para_index) {
    return url + "/" + cmsEdit.pageType + "/" + cmsEdit.pageId + "/" + cmsEdit.revisionId + "/" + paragraph_id + "/" + para_index

  },

  forceUrl: function(page_type,page_id) {
      return  cmsEdit.editURL + 'page' + "/" + page_type + "/" + page_id ;
  },

  htmlEditorList: function() {
    return $$('.cms_paragraph_html_editor_text_box');

  },

  pageChanged:function() {
      cmsEdit.pageModified = true;
      $('cms_save_changes').disabled = false;
      // Start a 2 minute timer to backup any changes
  },

  pageUnchanged: function() {
      cmsEdit.pageModified = false;
      $('cms_save_changes').disabled = true;
  },

  registerParagraph:function(para_index,obj) {
    cmsEdit.paragraphs.set(para_index,obj);

  },

  cleanupParagraphs: function() {
      cmsEdit.paragraphs.each(function(elem) {
        if(elem[1]) {
          cmsEdit.paragraphs.get(elem[0]).cleanup();
        }
      });

  },

    /* Page Loading Funcs */
    refreshPage: function() {
      if(cmsEdit.pageModified) {
        cmsEdit.destPageType = '';
        cmsEdit.destPageId = '';
        cmsEdit.destRevisionId = '';
        cmsEdit.destParams = '';
        cmsEdit.destAction = cmsEdit.gotoRefreshUrl;
        RedBox.showInline('cms_save_changes_dialog');
        return false;
     }
     else {
      cmsEdit.gotoRefreshUrl();
     }

    },

    refreshInfo: function() {
      new Ajax.Request(cmsEdit.url('refresh_info'));
    },


    reloadPage: function(page_type,page_id,site_template_id) {
      SCMS.hidePopupDiv('cms_select_page');
      if(site_template_id != cmsEdit.siteTemplateId) {
        var new_page_url = cmsEdit.forceUrl(page_type,page_id);
        if(cmsEdit.leavePage(new_page_url)) {
          setTimeout("document.location='" + new_page_url + "';",10);
        }

      }
      else {
        cmsEdit.loadPage(page_type,page_id,'');
      }
    },

    finishAction: function() {
      RedBox.close();
      cmsEdit.destAction(cmsEdit.destPageType,cmsEdit.destPageId ,cmsEdit.destRevisionId,cmsEdit.destParams );
    },

    cancelAction: function() {
      RedBox.close();
    },

    gotoPage: function() {
      return cmsEdit.leavePage(cmsEdit.pageUrl);
    },

    closeStyleWin: function() {
      if(cmsEdit.styleWin) {
        try {
          cmsEdit.styleWin.close();
          cmsEdit.styleWin = null;

        } catch(e) {}
      }
    },


    leavePage: function(url) {
      cmsEdit.closeStyleWin();
      if(cmsEdit.pageModified) {
        cmsEdit.destPageType = '';
        cmsEdit.destPageId = '';
        cmsEdit.destRevisionId = '';
        cmsEdit.destParams = url;
        cmsEdit.destAction = cmsEdit.gotoUrl;
        RedBox.showInline('cms_save_changes_dialog');
        return false;
      }
      else {
        return true;
      }
    },

    gotoUrl: function(page_type,page_id,revsion_id,params) {
      cmsEdit.closeStyleWin();

      document.location = params;
    },

    gotoRefreshUrl: function(page_type,page_id,revision_id,params) {
      cmsEdit.closeStyleWin();

        var new_page_url = cmsEdit.url('page');
        setTimeout("document.location='" + new_page_url + "';",10);
    },

    gotoDestUrl: function() {
      cmsEdit.closeStyleWin();

      document.location=cmsEdit.destParams;

    },

    saveFirst: function() {
      RedBox.close();
      if(cmsEdit.destAction == cmsEdit.fetchPage) {
        cmsEdit.sendChanges('save_changes_and_reload',
                            'new_page_type=' + cmsEdit.destPageType + '&new_page_id=' + cmsEdit.destPageId + '&new_revision_id=' + cmsEdit.destRevisionId,
                            true);

      }
      else if(cmsEdit.destAction == cmsEdit.submitTranslation) {
        cmsEdit.sendChanges('save_changes_and_build_translation',
                            cmsEdit.destParams,
                            true);
      }
      else if(cmsEdit.destAction == cmsEdit.gotoUrl) {
        cmsEdit.sendChanges('save_changes',
                            '',
                            false,
                            cmsEdit.gotoDestUrl);
      }
      else if(cmsEdit.destAction == cmsEdit.gotoRefreshUrl) {
        cmsEdit.sendChanges('save_changes',
                            '',
                            false,
                            cmsEdit.gotoRefreshUrl);
      }
    },


    loadPage: function(page_type,page_id,revision_id) {
      if(cmsEdit.pageModified) {
        cmsEdit.destPageType = page_type;
        cmsEdit.destPageId = page_id;
        cmsEdit.destRevisionId = revision_id;
        cmsEdit.destAction = cmsEdit.fetchPage;
        RedBox.showInline('cms_save_changes_dialog');
      }
      else {
        cmsEdit.fetchPage(page_type,page_id,revision_id);
      }
    },

    fetchPage: function(page_type,page_id,revision_id) {
      cmsEdit.closeStyleWin();

        var selectedPage = $('page_selector_' + cmsEdit.pageType + '_' + cmsEdit.pageId );
        if(selectedPage) selectedPage.className = "cms_ajax_link";



        RedBox.showOverlay();
        cmsEdit.preparePageRefresh();
        cmsEdit.pageType = page_type;
        cmsEdit.pageId = page_id;
        cmsEdit.revisionId = revision_id;

        var newSelectedPage = $('page_selector_' + page_type + '_' + page_id);
        if(newSelectedPage) newSelectedPage.className = "cms_ajax_link_selected";

        new Ajax.Request(cmsEdit.url('reload_page'),
                         { onComplete: function() { RedBox.close(); } });
    },

    preparePageRefresh: function() {
      cmsEdit.cleanupParagraphs();
      cmsEdit.paragraphs = $H({});
      cmsEdit.cancelAddFrameworkElement();
      cmsEdit.cancelAddParagraph();
    },

    /* Framework Element Adding Funcs */

    addSelectFrameworkElement: function() {
      SCMS.popupDiv('cms_add_framework_element');
    },

    selectFrameworkElement: function(type) {
      cmsEdit.cancelAddParagraph();

      SCMS.hidePopupDiv('cms_add_framework_element');
      Element.hide('cms_add_framework_element_icon');
      Element.show('cms_cancel_add_framework_element_icon');
      cmsEdit.displayAddFrameworkElems(true);
      cmsEdit.addElementType = type;

    },

    cancelAddFrameworkElement: function() {
      SCMS.hidePopupDiv('cms_add_framework_element');
      Element.show('cms_add_framework_element_icon');
      Element.hide('cms_cancel_add_framework_element_icon');
      cmsEdit.displayAddFrameworkElems(false);

    },

    createZoneElement: function(zone_idx) {
      if(cmsEdit.addElementType) {
        var para_info = cmsEdit.availableParagraphs.get(this.addElementType);
        params = $H({ zone: zone_idx,
              display_type: para_info[1],
              para_index: this.paraIndex });
        this.paraIndex++;

        cmsEdit.cancelAddFrameworkElement();
        new Ajax.Request(cmsEdit.url('add_paragraph'),
                  {
                    parameters : params.toQueryString(),
                    onComplete : function(resp) {
                      new Insertion.Top('cms_zone_' + zone_idx,
                                  resp.responseText);
                      cmsEdit.pageChanged();
                      cmsEdit.recreateSortables();
                      if(params.display_type == 'clear')
                        cmsEdit.displayZoneFrameworkParagraphs($('cms_zone_' + zone_idx),false);
                    }
                  }
                  );
      }
    },

    displayAddFrameworkElems: function(show) {
      var adds= $$('.cms_add_element_zone');
      adds.each(function(add) {
        show ? Element.show(add) : Element.hide(add);
      });
    },

    removeFrameworkFeature: function(para_index) {
      if(confirm("Are you sure you want to delete this framework feature?")) {
        var element = $('cms_paragraph_' + para_index).parentNode;
        cmsEdit.displayZoneFrameworkParagraphs(element,true);
        cmsEdit.confirmedDeleteParagraph(para_index);
      }
    },


    displayZoneFrameworkParagraphs: function(element,show) {
      var elems = getChildElementsByClass(element,'cms_rendered_wrapper');
      elems.each(function(add) {
        show ? Element.show(add) : Element.hide(add);
      });
    },

    /* Paragraph Adding Funcs */


  	addSelectParagraph: function() {
  		SCMS.popupDiv('cms_add_paragraph');
  	},



  	addParagraph: function(type,pub_id) {
      cmsEdit.cancelAddParagraph();
      SCMS.hidePopupDiv('cms_add_paragraph');
  		Element.hide('cms_add_paragraph_icon');
  		Element.show('cms_cancel_add_paragraph_icon');
  		cmsEdit.displayAddParagraphs(true);
  		if(pub_id)
  		  cmsEdit.addParagraphType = type + "_" + pub_id;
  		else
  		  cmsEdit.addParagraphType = type;

  	},

  	cancelAddParagraph: function() {
  		Element.hide('cms_cancel_add_paragraph_icon');
  		Element.show('cms_add_paragraph_icon');
  		cmsEdit.displayAddParagraphs(false);
      cmsEdit.addParagraphType = null;
  	},

  	displayAddParagraphs: function(show) {
  		var adds= $$('.cms_add_paragraph_zone');
  		adds.each(function(add) {
  			show ? Element.show(add) : Element.hide(add);
  		});
  	},

  	createParagraph:function(zone_idx) {
	if(cmsEdit.addParagraphType) {
	    var para = cmsEdit.availableParagraphs.get(cmsEdit.addParagraphType);

	    params = $H({ zone: zone_idx,
		  display_type: para[1],
		  para_index: this.paraIndex
		  });
            if(para[6] > 0) {
              params.set('pub_id',para[6]);
            }
	    this.paraIndex++;

	    if(para[0] != 'builtin') {
	      params.set('display_module',para[3]);
	    }

	    new Ajax.Request(cmsEdit.url('add_paragraph'),
		      {
			parameters : params.toQueryString(),
			onComplete : function(resp) {
			  new Insertion.Bottom('cms_zone_' + zone_idx,
				      resp.responseText);
			  cmsEdit.pageChanged();
			  cmsEdit.recreateSortables();
			  setTimeout("cmsEdit.editParagraph(" + params.get('para_index') + ");",10);
			}
		      }
		      );
		    }
	  cmsEdit.cancelAddParagraph();
	 },

   editParagraph: function(para_index) {
      para_index = Number(para_index);
      var para = cmsEdit.paragraphs.get(para_index);
      var para_info = cmsEdit.availableParagraphs.get(para.paragraph_type);

      if(cmsEdit.previewMode)
        return true;


      if(para.isCustomEditor()) {
        para.edit();
        return true;
      }

      SCMS.setKeyHandler(null);

        SCMS.remoteOverlay(cmsEdit.paragraphUrl(para_info[4],para.paragraph_id,para_index),
                           { parameters: { 'site_template_id' : cmsEdit.siteTemplateId }},'get' );
   },

   selectParagraph:function(para_id) {
      cmsEdit.unfocusSelectedParagraph();
      cmsEdit.unselectParagraph();
      $('cms_paragraph_menu_' + para_id).className = 'cms_paragraph_menu_selected';
      cmsEdit.selectedParagraph = para_id;

   },

   unselectParagraph:function() {
      if(cmsEdit.selectedParagraph && $('cms_paragraph_menu_' + cmsEdit.selectedParagraph)) {
        $('cms_paragraph_menu_' + cmsEdit.selectedParagraph).className = 'cms_paragraph_menu';
      }
      cmsEdit.selectedParagraph = null;
   },

   /* Paragraph Sorting */
  recreateSortables: function() {

    zones = $$('.cms_paragraph_zone');

    zone_name_list = [];
    zones.each(
           function(elem,idx) {
            zone_name_list.push(elem.id);
    });

    zones.each(
            function(elem,idx) {
            Sortable.create(elem.id,{
                dropOnEmpty:true,
                handle:'cms_paragraph_icon',
                tag:'div',
                only:'cms_paragraph',
                containment:zone_name_list,
                constraint:false,
                onUpdate:cmsEdit.saveParagraphPosition,
                starteffect:cmsEdit.startParagraphDrag,
                endeffect:cmsEdit.endParagraphDrag,
                reverteffect: cmsEdit.revertParagraphDrag,
                onUpdate:cmsEdit.pageChanged
                })

                });
    this.ParagraphMovement = true;

  },

  destroySortables: function() {
    $$('.cms_paragraph_zone').each(function(zone) {
      Sortable.destroy(zone.id);
    });


  },

  saveParagraphPosition: function() {


  },

  startParagraphDrag: function(elem) {
    cmsEdit.unselectParagraph();
    cmsEdit.displayAddParagraphs(false);

    var elem_id = SCMS.getElemNum(elem.id);
    var paraObj = cmsEdit.paragraphs.get(elem_id);
    paraObj.showPreview(true);


    var drops = $$('cms_paragraph_zone');
    drops.each(function(drop) {
      Element.addClassName(drop,'cms_paragraph_zone_drop');
    });

  },

  endParagraphDrag: function(elem) {
    var drops = $$('.cms_paragraph_zone');
    drops.each(function(drop) {
      Element.removeClassName(drop,'cms_paragraph_zone_drop');
    });

    var elem_id = SCMS.getElemNum(elem.id);
    var paraObj = cmsEdit.paragraphs.get(elem_id);

    paraObj.endPreview(true);


  },

  revertParagraphDrag: function(element, top_offset, left_offset) {
      new Effect.Move(element, { x: -left_offset, y: -top_offset, duration: 0.01,
          queue: {scope:'_draggable', position:'end'}
        });
  },

  /* Saving function */

  saveChanges: function() {
    cmsEdit.pageModified=false;
    $('cms_save_changes').disabled = true;
    cmsEdit.sendChanges('save_changes');

  },

  saveAsSend: function(version, name) {
    cmsEdit.hideSaveAs();
    cmsEdit.pageModified=false;
    $('cms_save_changes').disabled = true;
    var params = "version=" + version
    if(name) { params += "&name=" + name; }
    cmsEdit.sendChanges('save_as',params);
  },

  sendChanges: function(action,params,cleanup,callback) {

    tinyMCE.triggerSave();

    var update_params = cmsEdit._getParagraphOrder();
    update_params += cmsEdit._getParagraphData();
    if(params != undefined) {
      update_params += "&" + params;
    }

    if(cleanup != undefined && cleanup) {
      cmsEdit.cleanupParagraphs();
    }
    else {
      $('cms_saving_icon').style.visibility='visible';
    }

    new Ajax.Request(cmsEdit.url(action),
                     { method: "post",
                       parameters: update_params,
                       onComplete: function(req) {
                        if(callback) {
                          callback();
                        }
                       }
                     });


  },

  previewChanges: function() {
    cmsEdit.sendChanges('preview');
  },

  openPreviewWindow: function() {
    var url = cmsEdit.editURL + 'goto' + "/" + cmsEdit.pageType + "/" + cmsEdit.pageId + "/" + cmsEdit.revisionId + '?url=' + escape(cmsEdit.pageUrl);
    openWindow(url, 'edit_preview', null, null, 'yes', 'yes');
  },

  _getParagraphOrder: function() {
    zones = $$('.cms_paragraph_zone');
    var update_str = ""
    zones.each( function(zone) {

        var zone_id = SCMS.getElemNum(zone);

        var paras = zone.select(".cms_paragraph_editor");

        paras.each(function (para) {
            var  para_index = SCMS.getElemNum(para);
            var paragraph_id = cmsEdit.paragraphs.get(para_index).paragraph_id;

             update_str += "zone[" + zone_id + "][]=" + paragraph_id + "&";
        });


    });

    return update_str;

  },

  _getParagraphData: function() {
    var edit_paras = $$('.cms_paragraph_editor');
    var update_params  = ''
    edit_paras.each(function(para) {
      var para_index = SCMS.getElemNum(para);
      var paraObj = cmsEdit.paragraphs.get(para_index);
      if(paraObj && paraObj.isClientEditor()) {
        update_params += "&" + paraObj.paragraphData();
      }
    });
    return update_params;

  },

  /* Page Preview */

  hideEditors: function() {
    cmsEdit.paragraphs.each(function(elem) {
      if(elem[1]) {
        Element.hide('cms_paragraph_menu_' + elem[0]);
        cmsEdit.paragraphs.get(elem[0]).showPreview(false);
      }
    });

  },

  showEditors: function() {
    cmsEdit.paragraphs.each(function(elem) {
      if(elem[1]) {
        Element.show('cms_paragraph_menu_' + elem[0]);
        cmsEdit.paragraphs.get(elem[0]).endPreview(false);
      }
    });
  },

  previewPage: function() {

    cmsEdit.previewMode = true;
    tinyMCE.triggerSave();
    cmsEdit.destroySortables();
    Element.hide('cms_preview_icon');
    Element.show('cms_cancel_preview_icon');
    // Kill All Sortables
    // Put each paragraph in preview moe
    cmsEdit.hideEditors();

  },

  cancelPreview: function() {
    cmsEdit.previewMode = false;
    cmsEdit.recreateSortables();
    Element.show('cms_preview_icon');
    Element.hide('cms_cancel_preview_icon');
   // Recreate Sortables
    // Remove Preview Mode
    cmsEdit.showEditors();
  },

  /* Paragraph Moving */
  unfocusParagraph: function(para_index) {
    var para = cmsEdit.paragraphs.get(cmsEdit.focusedElem);
    if(para && para.isClientEditor()) {
      para.blur();
    }
  },

  unfocusSelectedParagraph: function() {
    if(cmsEdit.focusedElem) {
	$('cms_paragraph_html_editor_' + cmsEdit.focusedElem).blur();
    }
    cmsEdit.focusedElem = null;

  },

  focusParagraph: function(para_index) {
    cmsEdit.focusedElem = para_index;
    cmsEdit.unselectParagraph();

  },

  moveKey: function(evt) {
    if(cmsEdit.previewMode)
      return true;

    var arrow = SCMS.getArrowKey(evt)

    if(cmsEdit.focusedElem) {
      if(!cmsEdit.pageModified) {
	var para = cmsEdit.paragraphs.get(cmsEdit.focusedElem);
	if(para && para.isClientEditor()) {
	  if(!arrow) {
	    cmsEdit.pageChanged();
	  }
	}
      }
      if(SCMS.getEscapeKey(evt)) {
        cmsEdit.unfocusSelectedParagraph();
      }
    }

    if(!cmsEdit.selectedParagraph)
      return true;


    if(!arrow) {
       return true;
     }
     else  {
        cmsEdit.pageChanged();
        cmsEdit.showPreviewTimeout(cmsEdit.selectedParagraph);
        if(arrow == 'up') {

          if(!SCMS.moveElemUp('cms_paragraph_' + cmsEdit.selectedParagraph,'cms_paragraph')) {
            arrow = 'left';
          }

        }
        if(arrow == 'down') {
           if(!SCMS.moveElemDown('cms_paragraph_' + cmsEdit.selectedParagraph,'cms_paragraph')) {
            arrow='right';
           }
        }

        if(arrow == 'left' || arrow == 'right') {
          var elem = $('cms_paragraph_' + cmsEdit.selectedParagraph);
          var zone = elem.parentNode;
          var zones = $$('.cms_paragraph_zone');
          var idx = zones.indexOf(zone);
          if(arrow == 'right') {
            idx = (idx + 1) % zones.length;
          }
          else {
            if(--idx < 0)
              idx = zones.length - 1;
          }
          Element.remove(elem);
          if(arrow =='right') {
            SCMS.unshiftElem(zones[idx],elem,'cms_paragraph');

          }
          else {
            zones[idx].appendChild(elem);
          }
        }
        cmsEdit.endPreviewTimeout(cmsEdit.selectedParagraph);
     }

    return false;


  },

  showPreviewTimeout: function(para_id) {
      if(cmsEdit.paragraphs.get(para_id).timer) {
        clearTimeout(cmsEdit.paragraphs.get(para_id).timer);
      }
      else {
        cmsEdit.destroySortables();
        cmsEdit.paragraphs.get(para_id).showPreview(true);
      }
  },

  endPreviewTimeout: function(para_id) {
    if(cmsEdit.paragraphs.get(para_id).timer) {

    }
    cmsEdit.paragraphs.get(para_id).timer = setTimeout("cmsEdit.clearPreviewTimeout('" + para_id + "')",1200);
  },

  clearPreviewTimeout: function(para_id) {
        cmsEdit.paragraphs.get(para_id).timer = false;
        cmsEdit.paragraphs.get(para_id).endPreview(true);
        cmsEdit.recreateSortables();

  },

  /* Save As */

  saveAs: function() {
    SCMS.popupDiv('cms_save_as');
  },

  hideSaveAs: function() {
    SCMS.hidePopupDiv('cms_save_as');
  },

  saveAsSpecificSubmit: function(frm) {
    // Get Value
    var elem = frm.version;
    var value = elem.value;
    var name = frm.name.value;

    regexp = /^[0-9]*\.[0-9]{1,2}$/
    if(!regexp.test(value)) {
      alert(cmsEdit.txt.get('invalidVersionText'));
      return;
    }
    else {
      cmsEdit.closeBox();
      cmsEdit.saveAsSend(value, name);
    }


  },

  /* Paragraph Menu */

  showMenu: function(para_index) {
    var para = cmsEdit.paragraphs.get(para_index);
    var paragraph_type = para.paragraph_type;
    var opts = new Array();

    if(paragraph_type == 'clear') {
      opts = new Array([cmsEdit.txt.get('deleteFeatureText'),'js','cClick(); cmsEdit.removeFrameworkFeature(' + para_index + ');']);
    }
    else if(paragraph_type == 'lock') {
      opts = new Array([cmsEdit.txt.get('deleteFeatureText'),'js','cClick(); cmsEdit.deleteParagraph(' + para_index + ');']);
    }
    else {

      var txt = '';
      var style_txt='';

      var p_info = cmsEdit.availableParagraphs.get(paragraph_type);
      var p_features= p_info[5];
      if(p_features.length > 0 && p_features[0] != '' ) {

        txt += "<a href='javascript:void(0);' onclick='cClick(); cmsEdit.createParagraphStyle(\"" + para_index+ "\",\"" + paragraph_type+ "\");'>" +  cmsEdit.txt.get('createStyleText') + "</a><br/>";
        if(para.paragraph_feature == 0)
           style_txt = '<b class="selected">*' + cmsEdit.txt.get('currentStyleText') + cmsEdit.txt.get('defaultStyleText') + '</b>';
        else
          style_txt =  cmsEdit.txt.get('selectStyleText') + cmsEdit.txt.get('defaultStyleText');

        txt += "<a href='javascript:void(0);' onclick='cClick(); cmsEdit.selectParagraphStyle(\"" + para_index+ "\",0);'>" + style_txt + "</a><br/>";

        var header = false;
          p_features.each(function(feature) {
            var selectable_features = cmsEdit.getFeatures(cmsEdit.siteTemplateId, feature);
            selectable_features.each(function(feature) {

            if(para.paragraph_feature == feature[1] )
               style_txt = '<b class="selected">*' + cmsEdit.txt.get('currentStyleText') + feature[0] + '</b>';
            else
              style_txt =  cmsEdit.txt.get('selectStyleText') + feature[0];

            txt += "<a href='javascript:void(0);' onclick='cClick(); cmsEdit.selectParagraphStyle(\"" + para_index+ "\"," + feature[1] + ");'>" + style_txt  + "</a>";
            txt += " (<a href='javascript:void(0);' onclick='cClick(); cmsEdit.editParagraphStyle(\"" + para_index+ "\"," + feature[1] + ");'>" +  cmsEdit.txt.get('editStyleText') +  "</a>)";
            txt += " (<a href='javascript:void(0);' onclick='cClick(); cmsEdit.copyParagraphStyle(\"" + para_index+ "\"," + feature[1] + ");'>" +  cmsEdit.txt.get('copyStyleText') +  "</a>) <br/>";

            });
          });

      }

      if(paragraph_type != '_html' &&  paragraph_type != '_lock' && paragraph_type != '_clear') {
        txt += "<hr/>"
        txt += "<a href='javascript:void(0);' onclick='cClick(); cmsEdit.editParagraph(\"" + para_index + "\");'>" + cmsEdit.txt.get('editParagraphText') + "</a><br/>";
      }

      txt += "<hr/>"
      txt += "<a href='javascript:void(0);' onclick='cClick(); cmsEdit.deleteParagraph(\"" + para_index + "\");'>" + cmsEdit.txt.get('deleteParagraphText') + "</a><br/>";

      SCMS.customPopup(txt,"Action");
      return;

    }


    SCMS.popup(opts);
  },

  deleteParagraph: function(para_index) {
    if(confirm(cmsEdit.txt.get('deleteText'))) {
      cmsEdit.confirmedDeleteParagraph(para_index);
    }
  },

  confirmedDeleteParagraph: function(para_index) {
      var params = $H({ paragraph_id: cmsEdit.paragraphs.get(para_index).paragraph_id });
      new Ajax.Request(cmsEdit.url('delete_paragraph'),
                        { parameters: params.toQueryString() }
                        );

      cmsEdit.pageChanged();
      cmsEdit.paragraphs.get(para_index).showPreview(true);
      cmsEdit.paragraphs.set(para_index,null);
      Element.remove('cms_paragraph_' + para_index);
      cmsEdit.recreateSortables();

  },

  createParagraphStyle: function(para_index,paragraph_type) {

  var p_info = cmsEdit.availableParagraphs.get(paragraph_type);
  var p_features= p_info[5];

   var para = cmsEdit.paragraphs.get(para_index);
    var params = $H({ para_index: para_index,
                      paragraph_id: para.paragraph_id,
                      feature_type: p_features[0] });
    cmsEdit.styleWin =  openWindow(cmsEdit.templateUrl('popup_feature') + "?" + Object.toQueryString(params),'EditStyle' + cmsEdit.revisionId ,900,600,'yes','yes');
      cmsEdit.styleWin.focus();

  },


  selectParagraphStyle: function(para_index,feature_id) {
    var para = cmsEdit.paragraphs.get(para_index);
    var params = $H({ para_index: para_index,
                      paragraph_id: para.paragraph_id,
                      feature_id: feature_id });
    cmsEdit.pageChanged();
    new Ajax.Request( cmsEdit.url('set_paragraph_feature'),
                     { parameters: params.toQueryString(),
                       onComplete: function(req) { Element.replace('cms_paragraph_' + para_index, req.responseText); },
                       evalScripts:true
                     });
    cClick();
  },

  editParagraphStyle: function(para_index,feature_id) {
    var para = cmsEdit.paragraphs.get(para_index);
    var params = $H({ para_index: para_index,
                      paragraph_id: para.paragraph_id,
                      feature_id: feature_id });
    cmsEdit.styleWin = openWindow(cmsEdit.templateUrl('popup_feature',feature_id) + "?" + Object.toQueryString(params),'EditStyle' + cmsEdit.revisionId,900,650,'yes','yes');
      cmsEdit.styleWin.focus();
    cClick();
  },

 copyParagraphStyle: function(para_index,feature_id) {
    var para = cmsEdit.paragraphs.get(para_index);
    var params = $H({ para_index: para_index,
                      paragraph_id: para.paragraph_id,
                      copy_feature_id: feature_id });
    cmsEdit.styleWin = openWindow(cmsEdit.templateUrl('popup_feature',feature_id) + "?" + Object.toQueryString(params),'EditStyle' + cmsEdit.revisionId,900,650,'yes','yes');
      cmsEdit.styleWin.focus();
    cClick();
  },



  /* Modification History */

  showModificationHistory: function() {
    SCMS.popupDiv('cms_select_modification');
    if(!$('cms_mod_history_' + cmsEdit.revisionId)) {
      new Ajax.Updater('cms_select_modification',
                      cmsEdit.url('modification_history'));
    }
  },

  loadEdit: function(revision_id) {
    SCMS.hidePopupDiv('cms_select_modification');
    cmsEdit.loadPage(cmsEdit.pageType,cmsEdit.pageId,revision_id);


  },

  /* Translations */

  showTranslations: function() {
    SCMS.popupDiv('cms_revisions_languages');
  },

  loadTranslation: function(revision_id) {
    SCMS.hidePopupDiv('cms_revisions_languages');
    cmsEdit.loadPage(cmsEdit.pageType,cmsEdit.pageId,revision_id);
  },

  createTranslation: function(lang) {
    SCMS.setKeyHandler(null);
    var params = $H({ language: lang });
    new Ajax.Updater('page_info_div',
                    cmsEdit.url('create_translation'),
                    {
                      evalScripts:true,
                      parameters:params.toQueryString(),
                      onComplete: function(req) {
                        RedBox.addHiddenContent('page_info_div');
                      },
                      onLoading:function(req) {
                       RedBox.loading();
                      }
                    });
  },

  buildTranslation: function(frm) {
    if(cmsEdit.pageModified) {
      cmsEdit.destPageType = null;
      cmsEdit.destPageId = null;
      cmsEdit.destRevisionId = null;
      cmsEdit.destParams = Form.serialize(frm);
      cmsEdit.destAction = cmsEdit.submitTranslation;
      RedBox.showInline('cms_save_changes_dialog');
    }
    else {
      cmsEdit.submitTranslation(null,null,null,Form.serialize(frm));
    }
  },

  submitTranslation: function(page_type,page_id,revsion_id,params) {
    cmsEdit.closeBox();
    cmsEdit.cleanupParagraphs();
    new Ajax.Request(cmsEdit.url('build_translation'),
                    {
                      parameters:params
                    });
  },

  /* Versions */

  showVersions: function() {
    SCMS.popupDiv('cms_version_list');
    if(!$('cms_revision_history_' + cmsEdit.revisionId)) {
      new Ajax.Updater('cms_version_list',
                      cmsEdit.url('version_history'));
    }
  },

  loadVersion: function(revision_id) {
    SCMS.hidePopupDiv('cms_version_list');
    cmsEdit.loadPage(cmsEdit.pageType,cmsEdit.pageId,revision_id);
  },

  /* Page Activation / Deactivation */

  activateVersion: function() {
    if(cmsEdit.pageActive) {
        if(confirm(cmsEdit.txt.get('deactivateText'))) {
          new Ajax.Request(cmsEdit.url('deactivate_version'));
        }
    }
    else {
          new Ajax.Request(cmsEdit.url('activate_version'));
    }

  },

  /* Page Information */

  pageInfo: function() {
    SCMS.setKeyHandler(null);
    new Ajax.Updater('page_info_div',
                    cmsEdit.url('page_info'),
                    {
                      evalScripts:true,
                      onComplete: function(req) {
                        RedBox.addHiddenContent('page_info_div');
                      },
                      onLoading:function(req) {
                       RedBox.loading();
                      }
                    });
   },

   closeInfo: function() {
    var params = $('cms_page_info_form').serialize();

    new Ajax.Request(cmsEdit.url('update_info'),
                     { parameters: params }
                     );
    cmsEdit.pageChanged();
    cmsEdit.closeBox();
   },

   closeBox: function() {
    SCMS.setKeyHandler(cmsEdit.moveKey);
    RedBox.close();
   },

   /* Page Menu */

   pageMenu: function() {
    SCMS.popupDiv('cms_page_menu');
   },

   deletePopup: function(type) {
      new Ajax.Updater('page_info_div',
                    cmsEdit.url('delete_ask'),
                    {
                      parameters:'delete_type=' + type,
                      evalScripts:true,
                      onComplete: function(req) {
                        RedBox.addHiddenContent('page_info_div');
                      },
                      onLoading:function(req) {
                       RedBox.loading();
                      }
                    });

   },

   confirmedDelete: function(type) {

    cmsEdit.cleanupParagraphs();
    cmsEdit.paragraphs = $H({});
    new Ajax.Request(cmsEdit.url('delete'),
                     { parameters:'delete_type=' + type,
                       onComplete: function() {
                        cmsEdit.closeBox();
                        }});
   },


   submitParagraphData: function(frm,url,paragraph_id,para_idx) {
    var params = Form.serialize(frm);
    new Ajax.Request(cmsEdit.paragraphUrl(url,paragraph_id,para_idx),
                        { parameters: params,
                          onSuccess: function(transport) {
                            try {
                                if(!((transport.getResponseHeader('Content-type') || 'text/javascript').strip().match(/^(text|application)\/(x-)?(java|ecma)script(;.*)?$/i))) {
                                  Element.update('RB_window',transport.responseText.stripScripts());
                                  transport.responseText.evalScripts();

                                  }
                              }
                             catch (e) {
                               alert(e.toString());
                             }
                          }
                        }

                     );
      return false;
   },

   /* Page Connections */

   pageConnections: function() {
    SCMS.setKeyHandler(null);
    new Ajax.Updater('page_info_div',
                    cmsEdit.url('page_connections'),
                    {
                      evalScripts:true,
                      onComplete: function(req) {
                        RedBox.addHiddenContent('page_info_div');
                      },
                      onLoading:function(req) {
                       RedBox.loading();
                      }
                    });
   },

   closePageConnections: function() {
    var params = $('cms_page_connections').serialize();

    new Ajax.Request(cmsEdit.url('update_page_connections'),
                     { parameters: params }
                     );
    cmsEdit.pageChanged();
    cmsEdit.closeBox();
   },

   pageVariables: function() {
      SCMS.setKeyHandler(null);
      new Ajax.Updater('page_info_div',
                    cmsEdit.url('page_variables'),
                    {
                      evalScripts:true,
                      onComplete: function(req) {
                        RedBox.addHiddenContent('page_info_div');
                      },
                      onLoading:function(req) {
                       RedBox.loading();
                      }
                    });

   },

   updatePageVariables: function() {
    // Get the page variables
    // and update each
    var params = $('cms_page_variables').serialize();

    cmsEdit.sendChanges('update_page_variables',
                            params,
                            true,
                            cmsEdit.closePageVariables);
   },

  closePageVariables: function() {
    cmsEdit.pageChanged();
    cmsEdit.closeBox();
   },


 /* Triggered Accionts */
  commitAction: function(action_id) {
    setTimeout('cmsEdit.submitAction(' + action_id + ');',10);
  },

  submitAction: function(action_id) {
    params = { triggered_action_id: action_id};

    new Ajax.Request(cmsEdit.url('update_triggered_actions'),
                    { parameters: params });

  },

  deleteAction: function(action_id) {

    params = { triggered_action_id: action_id};

    new Ajax.Request(cmsEdit.url('delete_triggered_action'),
                    { parameters: params });

  },

  setParagraphValue: function(elem_id,html) {
        $('cms_paragraph_display_'+elem_id).innerHTML = "<div class='cms_paragraph_editor_cover'></div>" + html;

      cmsEdit.pageChanged();
  },

  changeVersion: function(version) {
    SCMS.remoteOverlay(cmsEdit.editURL + 'change_version' + "/" + cmsEdit.pageType + "/" + cmsEdit.pageId + "/" + cmsEdit.revisionId + '?version=' + version);
  }

}


window.onbeforeunload = cmsEdit.closeStyleWin;


/* Generic Paragraph Editor */
function cmsParagraph() {
}


cmsParagraph.prototype.isClientEditor = function() { return false };
cmsParagraph.prototype.isCustomEditor = function() { return false };

cmsParagraph.prototype.showPreview = function(drag) {
}

cmsParagraph.prototype.edit = function() {
}

cmsParagraph.prototype.blur= function() {
}


cmsParagraph.prototype.cleanup = function() {
}


cmsParagraph.prototype.endPreview = function(drag) {
}

/* Content Overlay Editor  Paragraph */
function cmsPublicationParagraph(paragraph_id, para_index, para_type,para_module,pub_id,paragraph_feature) {
  this.para_index = para_index;
  this.paragraph_id = paragraph_id;
  this.paragraph_type = para_type + "_" + pub_id;
  this.paragraph_module = para_module;
  this.publication_type = para_type;
  this.publication_id = pub_id;
  this.paragraph_feature = paragraph_feature;
}

cmsPublicationParagraph.prototype = new cmsParagraph();



/* Overlay Editor  Paragraph */
function cmsEditorParagraph(paragraph_id, para_index, para_type,para_module,paragraph_feature) {
  this.para_index = para_index;
  this.paragraph_id = paragraph_id;
  this.paragraph_type = para_type;
  this.paragraph_module = para_module;
  this.paragraph_feature = paragraph_feature;
}

cmsEditorParagraph.prototype = new cmsParagraph();

function cmsFrameworkElement(paragraph_id, para_index, para_type) {
  this.para_index = para_index;
  this.paragraph_id = paragraph_id;
  this.paragraph_type = para_type;
}

cmsFrameworkElement.prototype = new cmsParagraph();


/* HTML Paragraph Specific Code */
function cmsHtmlParagraph(paragraph_id, para_index) {
  this.para_index = para_index;
  this.paragraph_id = paragraph_id;
  this.paragraph_type = '_html';
}

cmsHtmlParagraph.prototype = new cmsParagraph();

cmsHtmlParagraph.prototype.isClientEditor = function() { return true };
cmsHtmlParagraph.prototype.isCustomEditor = function() { return true };

cmsHtmlParagraph.prototype.paragraphData = function() {
  var value = $('cms_paragraph_html_editor_' + this.para_index).value;
  return "paragraph[" + this.paragraph_id + "]=" + encodeURIComponent(value);
}

cmsHtmlParagraph.prototype.showPreview = function(drag) {
    var elem_id = this.para_index;
    if(drag) {
       tinyMCE.triggerSave();
      tinyMCE.execCommand('mceRemoveControl',false,'cms_paragraph_html_editor_' + elem_id);
    }
    $('cms_paragraph_display_'+elem_id).innerHTML = $('cms_paragraph_html_editor_' + elem_id).value;
    Element.hide('cms_paragraph_editor_' + elem_id);
    Element.show('cms_paragraph_display_' + elem_id);
}

cmsHtmlParagraph.prototype.cleanup = function() {
    var elem_id = this.para_index;
   tinyMCE.remove(tinyMCE.get('cms_paragraph_html_editor_' + elem_id));
}


cmsHtmlParagraph.prototype.endPreview = function(drag) {
    var elem_id = this.para_index;
    Element.hide('cms_paragraph_display_' + elem_id);
    Element.show('cms_paragraph_editor_' + elem_id);
    if(drag) {
      setTimeout("tinyMCE.execCommand('mceAddControl',true,'cms_paragraph_html_editor_" + elem_id + "');",5);
    }
    else {
      tinyMCE.execCommand('mceResetDesignMode');
    }
}

function cmsCodeParagraph(paragraph_id, para_index,para_type) {
  this.para_index = para_index;
  this.paragraph_id = paragraph_id;
  this.paragraph_type = '_' + para_type;
}


cmsCodeParagraph.prototype = new cmsParagraph();

cmsCodeParagraph.prototype.isCustomEditor = function() { return true; }
cmsCodeParagraph.prototype.edit = function() {
    var elem_id = this.para_index;
    var elem_height = Element.getHeight('cms_paragraph_display_' + elem_id);

    var params = { para_index: this.para_index, paragraph_id: this.paragraph_id };

    if(cmsEdit.editWin && !cmsEdit.editWin.closed) cmsEdit.editWin.close();
    cmsEdit.editWin = openWindow(cmsEdit.url('edit_code') + "?" + Object.toQueryString(params),'Edit Code',900,550,'yes','yes');


    cmsEdit.editWin.focus();

    return;
}
