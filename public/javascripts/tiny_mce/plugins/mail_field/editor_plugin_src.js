/**
 * $Id: editor_plugin_src.js 126 2006-10-22 16:19:55Z spocke $
 *
 * @author Moxiecode
 * @copyright Copyright  2004-2006, Moxiecode Systems AB, All rights reserved.
 */

/* Import plugin specific language pack */
tinyMCE.importPluginLanguagePack('mail_field');

var TinyMCE_MailFieldPlugin = {
	getInfo : function() {
		return {
			longname : 'Template Editor ',
			author : 'Pascal Rettig',
			version : '1.0'
		};
	},

	initInstance : function(inst) {
		tinyMCE.importCSS(inst.getDoc(), tinyMCE.baseURL + "/plugins/mail_field/css/content.css");
	},

	getControlHTML : function(cn) {
		switch (cn) {
			case "mail_field":
				return tinyMCE.getButtonHTML(cn, 'lang_mail_field_desc', '{$pluginurl}/images/mail_field.gif', 'mceMailField');
		}

		return "";
	},

	execCommand : function(editor_id, element, command, user_interface, value) {
		// Handle commands
		switch (command) {
			case "mceMailField":
				var field_name = "";
				var action = 'create';
				var template = new Array();
				var inst = tinyMCE.getInstanceById(editor_id);
				var focusElm = inst.getFocusElement();

				template['file']   = '../../plugins/mail_field/mail_field.htm'; // Relative to theme
				template['width']  = 430;
				template['height'] = 175;

				// Is selection a span
				if (focusElm != null && focusElm.nodeName.toLowerCase() == "span") {
					name = tinyMCE.getAttrib(focusElm, 'class');
					
					if (name.indexOf('mceNonEditable') == -1) // Not non-editable field
						return true;
                                        
                                        if(tinyMCE.getAttrib(focusElm, 'alt').indexOf('cmsField') == -1) // Not a field
                                          return true
					// Get rest of Flash items
					
					var cmsField = focusElm.childNodes[0];
					
					field_name = tinyMCE.getAttrib(cmsField,'alt');

					action = "update";
				}

				tinyMCE.openWindow(template, {editor_id : editor_id, inline : "yes", field_name : field_name, action : action});
			return true;
	   }

	   // Pass to next handler in chain
	   return false;
	},

	handleNodeChange : function(editor_id, node, undo_index, undo_levels, visual_aid, any_selection) {
		if (node == null)
			return;

		do {
			if (node.nodeName.toLowerCase() == "span" && tinyMCE.getAttrib(node, 'class').indexOf('mceNonEditable') == 0 &&
			     tinyMCE.getAttrib(node, 'alt').indexOf('cmsField') == 0) {
				tinyMCE.switchClass(editor_id + '_mail_field', 'mceButtonSelected');
				return true;
			}
		} while ((node = node.parentNode));

		tinyMCE.switchClass(editor_id + '_mail_field', 'mceButtonNormal');

		return true;
	}
};

tinyMCE.addPlugin("mail_field", TinyMCE_MailFieldPlugin);
