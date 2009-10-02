SCMS_popup = {

  init: function() {
  
    var win = window.opener ? window.opener : window.dialogArguments;
    var inst;
  
    if (!win) {
      // Try parent
      win = parent.parent;
  
      // Try top
      if (typeof(win.tinyMCE) == "undefined")
        win = top;
    }
  
    window.opener = win;
    this.windowOpener = win;
    this.popupOptions = win.SCMS.pickerOptions; 
  },
  
  onLoad: function(val) {
    document.onLoad = "SCMS_popup.bodyLoad();";
    this.loadFunc = val;
  
  },
  
  bodyLoad: function() {
    if(SCMS_popup.loadFunc) 
      eval(SCMS_popup.loadFunc);
  },
  
  options: function() {
    return this.popupOptions;
  },
  
  callback: function(val) {
    SCMS_popup.windowOpener.SCMS.pickerCallback(val);
  
  }
}
SCMS_popup.init();