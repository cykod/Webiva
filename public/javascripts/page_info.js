cmsPageInfo = {
  versionPopup: function(page_id,revision) {
    options_arr =      new Array(      
      [ '','Create New Minor Version',  'js', 'cmsPageInfo.createRevision("minor",' + page_id + ',' + revision + ')' ],
      [ '','Create New Major Version',  'js', 'cmsPageInfo.createRevision("major",' + page_id + ',' + revision + ')' ],
      [],
      [ '','Activate Revision',  'js', 'cmsPageInfo.activateRevision(' + page_id + ',' + revision + ')' ],
      [],
      [ '','Delete Revision',  'js', 'cmsPageInfo.deleteRevision(' + page_id + ',' + revision+ ')' ]
      );
     popupMenu('', options_arr);
 
  },
  
  activePopup: function(editor,page_id,revision_id) {
    if(editor) {
    popupMenu('', 
    new Array(      
      [ '','Edit Page',  'js', 'hideBox();  cmsEditor.reloadPage(' + page_id + ',' + revision_id + ')' ],
      [],
      [ '','Deactivate Translation',  'js', 'cmsPageInfo.deactivateTranslation(' + page_id + ',' + revision_id  + ')' ],
      [],
      [ '','Create New Minor Version',  'js', 'cmsPageInfo.createRevisionFromId("minor",' + page_id + ',' + revision_id + ')' ],
      [ '','Create New Major Version',  'js', 'cmsPageInfo.createRevisionFromId("major",' + page_id + ',' + revision_id + ')' ],
      [],
      [ '','Delete Translation',  'js', 'cmsPageInfo.deleteTranslation(' + page_id + ',' + revision_id + ')' ]
        ));
    }
    else {
    popupMenu('', 
    new Array(      
      [ '','Edit Page',  '/site/edit/page/' + page_id + '/' + revision_id ],
      [],
      [ '','Deactivate Translation',  'js', 'cmsPageInfo.deactivateTranslation(' + page_id + ',' + revision_id  + ')' ],
      [],
      [ '','Create New Minor Version',  'js', 'cmsPageInfo.createRevisionFromId("minor",' + page_id + ',' + revision_id + ')' ],
      [ '','Create New Major Version',  'js', 'cmsPageInfo.createRevisionFromId("major",' + page_id + ',' + revision_id + ')' ],
      [],
      [ '','Delete Translation',  'js', 'cmsPageInfo.deleteTranslation(' + page_id + ',' + revision_id + ')' ]
      ));
    }
  
  },


  existingPopup: function(editor,page_id,revision_id) {
  
     popupMenu('', 
     new Array(      
      [ '','Edit Page',  'js', 'hideBox(); cmsEditor.reloadPage(' + page_id + ',' + revision_id + ')' ],
      [],
      [ '','Make Active Translation',  'js', 'cmsPageInfo.activateTranslation(' + page_id + ',' + revision_id  + ')' ],
      [],
      [ '','Create New Minor Version',  'js', 'cmsPageInfo.createRevisionFromId("minor",' + page_id + ',' + revision_id + ')' ],
      [ '','Create New Major Version',  'js', 'cmsPageInfo.createRevisionFromId("major",' + page_id + ',' + revision_id + ')' ],
      [],
      [ '','Delete Translation',  'js', 'cmsPageInfo.deleteTranslation(' + page_id + ',' + revision_id + ')' ]
      )); 
  },
  
  nonePopup: function(page_id,revision,language) {
  
     popupMenu('', 
     new Array(      
      [ '','Create Translation',  'js', 'cmsPageInfo.createTranslation(' + page_id + ',' + revision + ',"' + language + '")' ]
      ));  
  },
  
  createRevisionFromId: function(revision_type,page_id,revision_id) {
    this.pageInfoUpdate(CMSEdit.url('create_revision'),
                         {
                          page_id: page_id,
                          revision_type: revision_type,
                          revision_id: revision_id
                         }
                        );
  
  },
  
  createRevision: function(revision_type,page_id,revision_number) {
  this.pageInfoUpdate(CMSEdit.url('create_revision'),
                         {
                          page_id: page_id,
                          revision_type: revision_type,
                          revision: revision_number
                         }
                        );
  
  
  },
  
  activateRevision: function(page_id,revision_number) {
      this.pageInfoUpdate(CMSEdit.url('activate_revision'),
                        {
                         revision: revision_number
                        });
                        
     
  },
  
  deactivateRevision: function(page_id,revision_number) {
      this.pageInfoUpdate(CMSEdit.url('deactivate_revision'),
                        {
                         revision: revision_number
                        });
                        
     
  },
  
  deleteRevision: function(page_id, revision_number) {
      this.pageInfoUpdate(CMSEdit.url('delete_revision'),
                        {
                         revision: revision_number
                        });
                        
  
  
  },
  
  activateTranslation: function(page_id,revision_id) {
    this.pageInfoUpdate(CMSEdit.url('activate_revision'),
                        {
                         revision_id: revision_id
                        });
                        
    
  
  },
  
  deactivateTranslation: function(page_id,revision_id) {
    this.pageInfoUpdate(CMSEdit.url('deactivate_revision'),
                        {
                         revision_id: revision_id
                        });
                        
    
  
  
  },  
  
  deleteTranslation: function(page_id,revision_id) {
    this.pageInfoUpdate(CMSEdit.url('delete_translation'),
                        {
                         revision_id: revision_id
                        });
  },
  
  createTranslation: function(page_id,revision,language) {
    cmsEditor.loadOverlayUrl(CMSEdit.url('new_translation') + '?revision=' + revision + '&language=' + escape(language));
  
  },
  
  pageInfoUpdate: function(url,params) {
    parameters = $H(params);
    new Ajax.Updater('_cms_page_info_table',
                     url,
                     { 
                      parameters: parameters.toQueryString(),
                      evalScripts:true
                     }
                    );
  
  }
  


};