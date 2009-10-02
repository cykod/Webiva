tinyMCE.importPluginLanguagePack('stylemanager');


var CMS_StyleManagerPlugin = {
	getInfo : function() {
		return {
			longname : 'Style Manager',
			author : 'Pascal Rettig',
			authorurl : '',
			infourl : '',
			version : "0.01"
		};
	},

	getControlHTML : function(cn) {
		switch (cn) {
			case "stylemanager":
				return "<span style='position:relative; top:-5px; padding:2px; border:1px solid #000000; background-color:white; width:170px;' class='cmsSelector'>Paragraph   <b><a href=\"javascript:tinyMCE.execInstanceCommand('{$editor_id}','cmsStyleManager');\">Styles &gt;</a></b></span>";
				
		}

		return "";
	},

	execCommand : function(editor_id, element, command, user_interface, value) {
		switch (command) {
			case "cmsStyleManager":
			  alert('Opening Style');
				return true;
		}

		return false;
	},
  
	cleanup : function(type, content) {
		return content;
	},

	handleNodeChange : function(editor_id, node, undo_index, undo_levels, visual_aid, any_selection) {
		return;
	},


};

tinyMCE.addPlugin("stylemanager", CMS_StyleManagerPlugin);
