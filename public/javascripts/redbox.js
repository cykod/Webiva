
var RedBox = {

  showInline: function(id)
  {
    this.showOverlay();
    new Effect.Appear('RB_window', {duration: 0.4, queue: 'end'});        
    return this.cloneWindowContents(id);
  },

  loading: function()
  {
    this.showOverlay();
    Element.show('RB_loading');
    this.setWindowPosition();
  },

  addHiddenContent: function(id)
  {
    this.removeChildrenFromNode($('RB_window'));
    this.moveChildren($(id), $('RB_window'));
    Element.hide('RB_loading');
    
  	
    
    new Effect.Appear('RB_window', {duration: 0.4, queue: 'end'});  
    this.setWindowPosition();
    var selects = $('RB_window').select('select');
  	for (i = 0; i != selects.length; i++) {
  		selects[i].style.visibility = "visible";
  	}

  },

  close: function()
  {
    document.onscroll = null;
    window.onresize = null;
    
    Element.hide('RB_window');
    Element.hide('RB_overlay');
    //new Effect.Fade('RB_window', {duration: 0.4});
    //new Effect.Fade('RB_overlay', {duration: 0.4});
    this.showSelectBoxes();
    Element.remove('RB_redbox');
  },

  showOverlay: function()
  {
    if ($('RB_redbox'))
    {
      Element.update('RB_redbox', "");
      new Insertion.Top($('RB_redbox'), '<div id="RB_window" style="display: none;"></div><div id="RB_overlay" style="display: none;"></div>');  
    }
    else
    {
      new Insertion.Top(document.body, '<div id="RB_redbox" align="center"><div id="RB_window" style="display: none;"></div><div id="RB_overlay" style="display: none;"></div></div>');      
    }
    new Insertion.Bottom('RB_redbox', '<div id="RB_loading" style="display: none"></div>');  

    this.setOverlaySize();
    this.hideSelectBoxes();
    
    Element.show('RB_overlay');
    //new Effect.Appear('RB_overlay', {duration: 0.2, to: 0.4, queue: 'end'});
    
    this.yScroll = this.getYScroll();
    document.onscroll = RedBox.scrollAdjust;
    window.onresize = RedBox.windowResize;
  },
  
  scrollAdjust: function() {
    RedBox.setOverlaySize();
    //
  	//window.scrollTo(0,RedBox.yScroll);
  },

  windowResize: function() {
    RedBox.setWindowPosition();
    RedBox.setOverlaySize();
  },

	getYScroll: function(){

		var yScroll;
	
		if (self.pageYOffset) {
			yScroll = self.pageYOffset;
		} else if (document.documentElement && document.documentElement.scrollTop){	 // Explorer 6 Strict
			yScroll = document.documentElement.scrollTop;
		} else if (document.body) {// all other Explorers
			yScroll = document.body.scrollTop;
		}
	
		return yScroll;
	},

	getPageSize: function(){
	
		var xScroll, yScroll;
		
		if (window.innerHeight && window.scrollMaxY) {	
			xScroll = document.body.scrollWidth;
			yScroll = window.innerHeight + window.scrollMaxY;
		} else if (document.body.scrollHeight > document.body.offsetHeight){ // all but Explorer Mac
			xScroll = document.body.scrollWidth;
			yScroll = document.body.scrollHeight;
		} else { // Explorer Mac...would also work in Explorer 6 Strict, Mozilla and Safari
			xScroll = document.body.offsetWidth;
			yScroll = document.body.offsetHeight;
		}
		
		var windowWidth, windowHeight;
		if (self.innerHeight) {	// all except Explorer
			windowWidth = self.innerWidth;
			windowHeight = self.innerHeight;
		} else if (document.documentElement && document.documentElement.clientHeight) { // Explorer 6 Strict Mode
			windowWidth = document.documentElement.clientWidth;
			windowHeight = document.documentElement.clientHeight;
		} else if (document.body) { // other Explorers
			windowWidth = document.body.clientWidth;
			windowHeight = document.body.clientHeight;
		}	
		
		// for small pages with total height less then height of the viewport
		if(yScroll < windowHeight){
			pageHeight = windowHeight;
		} else { 
			pageHeight = yScroll;
		}
	
		// for small pages with total width less then width of the viewport
		if(xScroll < windowWidth){	
			pageWidth = windowWidth;
		} else {
			pageWidth = xScroll;
		}
	
	
		arrayPageSize = new Array(pageWidth,pageHeight,windowWidth,windowHeight) 
		return arrayPageSize;
	},

 setOverlaySize: function()
  {
        if (window.innerHeight && window.scrollMaxY) 
        {    
            yScroll = window.innerHeight + window.scrollMaxY;
        } 
        else if (document.body.scrollHeight > document.body.offsetHeight)
        { // all but Explorer Mac
            yScroll = document.body.scrollHeight;
        } 
        else 
        { // Explorer Mac...would also work in Explorer 6 Strict, Mozilla and Safari
            yScroll = document.body.offsetHeight;
        }

        if (self.innerHeight) 
        {    // all except Explorer
            windowHeight = self.innerHeight;
        } 
        else if (document.documentElement && document.documentElement.clientHeight) 
        { // Explorer 6 Strict Mode
            windowHeight = document.documentElement.clientHeight;
        } 
        else if (document.body) 
        { // other Explorers
            windowHeight = document.body.clientHeight;
        }    

        // for small pages with total height less then height of the viewport
        if(yScroll < windowHeight)
        {
            yScroll = windowHeight;
        }
    var sz = RedBox.getPageSize();
    $("RB_overlay").style['width'] = sz[0] +"px";
    $("RB_overlay").style['height'] = yScroll +"px";
  },
  

  setWindowPosition: function()
  {
    var pagesize = this.getPageSize();  
  
    $("RB_window").style['width'] = 'auto';
    $("RB_window").style['height'] = 'auto';

	var arrayPageSize = this.getPageSize();
    var pageScroll = this.getYScroll();
    
    var dimensions = Element.getDimensions($("RB_window"));
    var width = dimensions.width;
    var height = dimensions.height;        
    
    var window_top = (pageScroll + (pagesize[1] - height)/2)
    if(window_top < 0)
      window_top = 0;
    
    $("RB_window").style['left'] = ((pagesize[0] - width)/2) + "px";
    $("RB_window").style['top'] =  window_top + "px";
  },


  getPageSize: function() {
    var de = document.documentElement;
    var w = window.innerWidth || self.innerWidth || (de&&de.clientWidth) || document.body.clientWidth;
    var h = window.innerHeight || self.innerHeight || (de&&de.clientHeight) || document.body.clientHeight;
  
    arrayPageSize = new Array(w,h) 
    return arrayPageSize;
  },

  removeChildrenFromNode: function(node)
  {
    while (node.hasChildNodes())
    {
      node.removeChild(node.firstChild);
    }
  },

  moveChildren: function(source, destination)
  {
    while (source.hasChildNodes())
    {
      destination.appendChild(source.firstChild);
    }
  },

  cloneWindowContents: function(id)
  {
    var content = $(id).cloneNode(true);
    content.style['display'] = 'block';
    $('RB_window').appendChild(content);  

    this.setWindowPosition();
    return content;
  },
  
  hideSelectBoxes: function()
  {
  	selects = document.getElementsByTagName("select");
  	for (i = 0; i != selects.length; i++) {
  		selects[i].style.visibility = "hidden";
  	}
  },

  showSelectBoxes: function()
  {
  	selects = document.getElementsByTagName("select");
  	for (i = 0; i != selects.length; i++) {
  		selects[i].style.visibility = "visible";
  	}
  }



}
