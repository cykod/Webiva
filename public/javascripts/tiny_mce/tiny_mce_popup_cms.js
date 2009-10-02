// Some global instances, this will be filled later
var tinyMCE = null, tinyMCELang = null;

function TinyMCE_Popup() {
};

TinyMCE_Popup.prototype = {
	findWin : function(w) {
		var c;

		// Check parents
		c = w;
		while (c && (c = c.parent) != null) {
			if (typeof(c.tinyMCE) != "undefined")
				return c;
		}

		// Check openers
		c = w;
		while (c && (c = c.opener) != null) {
			if (typeof(c.tinyMCE) != "undefined")
				return c;
		}

		// Try top
		if (typeof(top.tinyMCE) != "undefined")
			return top;

		return null;
	},

	init : function() {
		var win = window.opener ? window.opener : window.dialogArguments, c;
		var inst;

		if (!win)
			win = this.findWin(window);

		if (!win) {
			alert("tinyMCE object reference not found from popup.");
			return;
		}

		window.opener = win;
		this.windowOpener = win;
		this.onLoadEval = "";

		// Setup parent references
		tinyMCE = win.tinyMCE;
		tinyMCELang = win.tinyMCELang;

		inst = tinyMCE.selectedInstance;
		this.isWindow = tinyMCE.getWindowArg('mce_inside_iframe', false) == false;
		this.storeSelection = (tinyMCE.isRealIE) && !this.isWindow && tinyMCE.getWindowArg('mce_store_selection', true);

		if (this.isWindow)
			window.focus();

		// Store selection
		if (this.storeSelection)
			inst.selectionBookmark = inst.selection.getBookmark(true);

		// Setup dir
		if (tinyMCELang['lang_dir'])
			document.dir = tinyMCELang['lang_dir'];

		tinyMCE.addEvent(window, "load", this.onLoad);
	},

	onLoad : function() {
		var dir, i, elms, body = document.body;

		if (body.style.display == 'none')
			body.style.display = 'block';

		// Execute real onload (Opera fix)
		if (tinyMCEPopup.onLoadEval != "")
			eval(tinyMCEPopup.onLoadEval);
	},

	executeOnLoad : function(str) {
		if (tinyMCE.isOpera)
			this.onLoadEval = str;
		else
			eval(str);
	},

	getWindowArg : function(name, default_value) {
		return tinyMCE.getWindowArg(name, default_value);
	},

	restoreSelection : function() {
		if (this.storeSelection) {
			var inst = tinyMCE.selectedInstance;

			inst.getWin().focus();

			if (inst.selectionBookmark)
				inst.selection.moveToBookmark(inst.selectionBookmark);
		}
	},

	execCommand : function(command, user_interface, value) {
		var inst = tinyMCE.selectedInstance;

		this.restoreSelection();
		inst.execCommand(command, user_interface, value);

		// Store selection
		if (this.storeSelection)
			inst.selectionBookmark = inst.selection.getBookmark(true);
	},

	close : function() {
		tinyMCE.closeWindow(window);
	},

	pickColor : function(e, element_id) {
		tinyMCE.selectedInstance.execCommand('mceColorPicker', true, {
			element_id : element_id,
			document : document,
			window : window,
			store_selection : false
		});
	},

	openBrowser : function(element_id, type, option) {
		var cb = tinyMCE.getParam(option, tinyMCE.getParam("file_browser_callback"));
		var url = document.getElementById(element_id).value;

		tinyMCE.setWindowArg("window", window);
		tinyMCE.setWindowArg("document", document);

		// Call to external callback
		if (eval('typeof(tinyMCEPopup.windowOpener.' + cb + ')') == "undefined")
			alert("Callback function: " + cb + " could not be found.");
		else
			eval("tinyMCEPopup.windowOpener." + cb + "(element_id, url, type, window);");
	},

	importClass : function(c) {
		window[c] = function() {};

		for (var n in window.opener[c].prototype)
			window[c].prototype[n] = window.opener[c].prototype[n];

		window[c].constructor = window.opener[c].constructor;
	}

	};

// Setup global instance
var tinyMCEPopup = new TinyMCE_Popup();

tinyMCEPopup.init();
