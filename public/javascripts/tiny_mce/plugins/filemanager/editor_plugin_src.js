/**
 * $Id: editor_plugin_src.js 126 2006-10-22 16:19:55Z spocke $
 *
 * @author Moxiecode
 * @copyright Copyright  2004-2006, Moxiecode Systems AB, All rights reserved.
 */
tinyMCE.importPluginLanguagePack('filemanager');

(function() {
   tinymce.PluginManager.requireLangPack('filemanager');

   tinymce.create('tinymce.plugins.FilemanagerPlugin', {

        init: function(ed,url) {
          ed.addCommand('cmsFileManager', function() {

                          var se = ed.selection;

                          if (se != null && tinymce.DOM.getAttrib(se, 'class').indexOf('mceItem') != -1)
			    return true;

                          ed.windowManager.open({
                            file: '/website/file/popup?select=all&callback=MCE_Popup.imageCallback&field={$editor_id}&mce=1',
                                                  width: 700,
                                                  height: 400,

                                                },
                                               {editor_id : editor_id, inline : "yes", resizeable: "yes", scrollbars: "yes" }
                                               );

			  return true;
                        });

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

