var url = tinyMCE.getParam("flash_external_list_url");
if (url != null) {
	// Fix relative
	if (url.charAt(0) != '/' && url.indexOf('://') == -1)
		url = tinyMCE.documentBasePath + "/" + url;

	document.write('<sc'+'ript language="javascript" type="text/javascript" src="' + url + '"></sc'+'ript>');
}

function init() {
	tinyMCEPopup.resizeToInnerSize();

	var formObj = document.forms[0];
	var field_name = tinyMCE.getWindowArg('field_name');

	formObj.field_name.value = field_name;
	formObj.field_name.focus();
	formObj.insert.value = tinyMCE.getLang('lang_' + tinyMCE.getWindowArg('action'), 'Insert', true);

}

function insertField() {
	var formObj = document.forms[0];
	var html      = '';
	var field_name      = formObj.field_name.value;
	html += '<span class="mceNonEditable" alt="cmsField"><span alt="' + field_name + '">' + field_name + '</span></span>&nbsp;';

	tinyMCEPopup.execCommand("mceInsertContent", true, html);
	tinyMCE.selectedInstance.repaint();

	tinyMCEPopup.close();
}
