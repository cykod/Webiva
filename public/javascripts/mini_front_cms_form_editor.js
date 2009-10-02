tinyMCE.init({
          theme : "advanced",
          theme_advanced_layout_manager: "SimpleLayout",
          auto_reset_designmode : true,
          mode: 'specific_textareas',
          editor_selector: 'cmsFormMceEditor',
          valid_elements: "*[*]",
          plugins: 'table,',
          extend_valid_elements: 'a[name|href|target|title|onclick]',
          theme_advanced_buttons1 : "bold,italic,underline,separator,bullist,numlist,undo,redo",
          theme_advanced_buttons2 : "",
          theme_advanced_buttons3 : "",
          theme_advanced_toolbar_location : "bottom",
          theme_advanced_toolbar_align: 'left',
          debug : false,
          relative_urls : false,
      	  remove_script_host : true,
          width: "100%"

       });

