(function() {
   tinymce.PluginManager.requireLangPack('filemanager');

   tinymce.create('tinymce.plugins.FilemanagerPlugin', {

        init: function(ed,url) {
          ed.addCommand('cmsFileManager', function() {

                          var se = ed.selection;
                          var elm = ed.selection.getNode();

                         var dom = ed.dom;
                         if (elm != null && ed.dom.getAttrib(elm, 'class').indexOf('mceItem') != -1)
			   return true;

                          ed.windowManager.open({
                            file: '/website/file/popup?select=all&callback=MCE_Popup.imageCallback&mce=1',
                                                  width: 1000,
                                                  height: 500,
                                                  scrollbars: true,
                                                  resizeable: true
                                                },
                                               {inline : "yes" , resizeable: "yes", scrollbars: "yes" }
                                               );

			  return true;
                        });
          ed.addCommand('cmsSaveChanges', function() {
                          cmsEdit.saveChanges();

                        });
          ed.addButton('filemanager', {
				title : 'filemanager.desc',
				cmd : 'cmsFileManager',
				image :  url + '/img/filemanager.gif'
			});
          ed.addShortcut('ctrl+s','filemanager.save_changes','cmsSaveChanges');


        },

        getInfo : function() {
		return {
			longname : 'File Manager',
			author : 'Pascal Rettig',
			authorurl : '',
			infourl : '',
			version : "0.01"
		};
	}

                  });

   tinymce.PluginManager.add('filemanager',tinymce.plugins.FilemanagerPlugin);

 }

)();

