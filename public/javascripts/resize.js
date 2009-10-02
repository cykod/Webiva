Resizeable = Class.create();

Resizeable.prototype = {

  startX: null,
  startY: null,
  startWidth: null,
  startHeight: null,
  active: false,
  elem: null,
  cont: null,
  handle: null,
  
  onend: null,
  
  minWidth: 0,
  minHeight: 0,
  
  
  initialize: function(container,element,options) {
    this.cont = $(container);
    this.elem = $(element);
    
    if(options.minWidth) this.minWidth = options.minWidth;
    if(options.minHeight) this.minHeight = options.minHeight;
    
    if(options.onEnd) {
      this.onend = options.onEnd;
    }
    
    this.handle = $(options.handle);
    
    Element.makePositioned(container);
    
    this.eventMouseDown = this.onMouseDown.bindAsEventListener(this);
    this.eventMouseUp = this.onMouseUp.bindAsEventListener(this);
    this.eventMouseMove = this.onMouseMove.bindAsEventListener(this);
    
    Event.observe(this.handle, "mousedown", this.eventMouseDown);
    Event.observe(document, "mouseup", this.eventMouseUp);
    Event.observe(document, "mousemove", this.eventMouseMove);
    Event.observe(this.handle, "mousemove", this.eventMouseMove);
    
    this.heightDiff = this.cont.getHeight() - this.elem.getHeight();

  },
  
  mousePos: function(e) {
    return { x: Event.pointerX(e), y: Event.pointerY(e) };
  },
  
  onMouseDown: function(e) {
    var pos = this.mousePos(e);
    this.startX = pos.x;
    this.startY = pos.y;
    this.containerWidth = this.cont.getWidth();
    this.containerHeight = this.cont.getHeight();
    document.body.focus();  // Keep firefox from dragging selected text
    document.onselectstart=function(event){window.event.returnValue=false; return false;} // Prevent IE highlight text
    this.handle.ondragstart = function() { return false; }// Prevent IE image drag
    this.active = true;
    
    return false; // Cancel additional events
  },
  
  onMouseUp: function(e) {
    if(this.active) { 
      this.onMouseMove(e);
      document.onselectstart=null; // Cancel IE funcs
      this.handle.ondragstart = null; // Cancel IE funcs
      this.active = false;
      if(this.onend) this.onend();
      return false; // Cancel additional events
    }
  },
  
  onMouseMove: function(e) {
    if(this.active) {
      var pos = this.mousePos(e);
      var diffX = pos.x - this.startX;
      var diffY = pos.y - this.startY;
      
      
      var newWidth = (this.containerWidth + diffX);
      if(newWidth < this.minWidth) newWidth = this.minWidth;
      var newHeight = (this.containerHeight + diffY);
      if(newHeight < this.minHeight) newHeight = this.minHeight;

      this.cont.style.width =  newWidth + "px";
      this.cont.style.height = newHeight + "px";

      
      //this.elem.style.width = (this.startWidth + diffX) + "px";
      this.elem.style.height = (newHeight - this.heightDiff) + "px";
      
     
      if(Prototype.Browser.WebKit) window.scrollBy(0,0);
      document.body.focus();   // Keep firefox from dragging selected text
      
      return false;
      
    }
  }

};
