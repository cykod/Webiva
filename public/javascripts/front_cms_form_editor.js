tinyMCE.init({
          theme : "advanced",
          theme_advanced_layout_manager: "SimpleLayout",
          auto_reset_designmode : true,
          mode: 'specific_textareas',
          editor_selector: 'cmsFormMceEditor',
          valid_elements: "*[*]",
          plugins: 'table,paste',
          extend_valid_elements: 'a[name|href|target|title|onclick]',
          theme_advanced_buttons1 : "pastetext,pasteword,bold,italic,underline,separator,strikethrough,justifyleft,justifycenter,justifyright,justifyfull,bullist,numlist,outdent,indent,undo,redo,anchor,link,unlink,hr,forecolor,backcolor",
          theme_advanced_buttons2 : "formatselect,fontselect,fontsizeselect,styleselect,table,cell_props,row_props",
          theme_advanced_blockformats: "p,div,h1,h2,h3,h4,h5,h6,blockquote,dt,dd,code,samp",
          theme_advanced_buttons3 : "",
          theme_advanced_toolbar_location : "top",
          theme_advanced_toolbar_align: 'left',
          debug : false,
          relative_urls : false,
	       remove_script_host : true,
          width: "100%"
       });

