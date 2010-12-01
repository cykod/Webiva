var mceDefaultOptions = {
          theme : "advanced",
          theme_advanced_layout_manager: "SimpleLayout",
          auto_reset_designmode : true,
          mode: 'specific_textareas',
          editor_selector: 'cmsFormMceEditor',
          valid_elements: "*[*]",
          plugins: 'table,filemanager,advimage,advlink,paste',
          extend_valid_elements: 'a[name|href|target|title|onclick]',
          theme_advanced_buttons1 : "bold,italic,underline,separator,strikethrough,justifyleft,justifycenter,justifyright,justifyfull,bullist,numlist,outdent,indent,undo,redo,pastetext,pasteword,anchor,link,unlink,image,filemanager,hr",
          theme_advanced_buttons2 : "forecolor,backcolor,formatselect,fontselect,fontsizeselect,styleselect",
          theme_advanced_blockformats: "p,div,h1,h2,h3,h4,h5,h6,blockquote,dt,dd,code,samp",
          theme_advanced_buttons3 : "tablecontrols,code",
          theme_advanced_toolbar_location : "top",
          theme_advanced_toolbar_align: 'left',
          external_link_list_url: "/website/edit/links",
          debug : false,
          relative_urls : false,
      	  remove_script_host : true,
      	  body_class : 'monthly_tip',
          width: "100%",
          gecko_spellcheck : true,
         image_insert_url: "/website/file/manage"

       };
       
try {
  if(cmsEditorOptions) {
    mceDefaultOptions = Object.extend(mceDefaultOptions,cmsEditorOptions)
  }
}
catch(err) {  }

tinyMCE.init(mceDefaultOptions);
