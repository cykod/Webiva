/*
  Proto!MultiSelect 0.2
  - Prototype version required: 6.0
  
  Credits:
  - Idea: Facebook + Apple Mail
  - Caret position method: Diego Perini <http://javascript.nwbox.com/cursor_position/cursor.js>
  - Guillermo Rauch: Original MooTools script
  - Ran Grushkowsky/InteRiders Inc. : Porting into Prototype and further development
  
  Changelog:
  - 0.1: translation of MooTools script
  - 0.2: renamed from Proto!TextboxList to Proto!MultiSelect, added new features/bug fixes
        added feature: support to fetch list on-the-fly using AJAX    Credit: Cheeseroll
        added feature: support for value/caption
        added feature: maximum results to display, when greater displays a scrollbar   Credit: Marcel
        added feature: filter by the beginning of word only or everywhere in the word   Credit: Kiliman
        added feature: shows hand cursor when going over options
        bug fix: the click event stopped working
        bug fix: the cursor does not 'travel' when going up/down the list   Credit: Marcel
*/

/* Copyright: InteRiders <http://interiders.com/> - Distributed under MIT - Keep this message! */

Object.extend(Event, { KEY_COMMA: 188 });

var ResizableTextbox = Class.create({
  
  initialize: function(element, options) {
    var that = this;
	this.options = $H({
	    min: 5,
	    max: 500,
	    step: 7
	  });
    this.options.update(options);
    this.el = $(element);
    this.width = this.el.offsetWidth;
    this.el.observe(
      'keyup', function() {
        var newsize = that.options.get('step') * $F(this).length;
        if(newsize <= that.options.get('min')) newsize = that.width;
        if(! ($F(this).length == this.retrieveData('rt-value') || newsize <= that.options.min || newsize >= that.options.max))
          this.setStyle({'width': newsize});
      }).observe('keydown', function() {
        this.cacheData('rt-value', $F(this).length);
      });
  }
});

var TextboxList = Class.create({ 
  
  initialize: function(element, options) {
	this.options = $H({/*
	    onFocus: $empty,
	    onBlur: $empty,
	    onInputFocus: $empty,
	    onInputBlur: $empty,
	    onBoxFocus: $empty,
	    onBoxBlur: $empty,
	    onBoxDispose: $empty,*/
	    resizable: {},
	    className: 'bit',
	    separator: ',',
	    extrainputs: true,
	    startinput: true,
	    hideempty: true,
		newValues: false,
		newValueDelimiters: ['[',']'],
		spaceReplace: '',
	    fetchFile: undefined,
		fetchMethod: 'get',
	    results: 10,
	    wordMatch: false
	});
    this.options.update(options);
    this.element = $(element).hide();    
    this.bits = new Hash();
    this.events = new Hash();
    this.count = 0;
    this.current = false;
    this.maininput = this.createInput({'class': 'maininput'});
    this.holder = new Element('ul', {
      'class': 'holder'
    }).insert(this.maininput);
    this.element.insert({'before':this.holder});
    this.holder.observe('click', function(event){
          event.stop();
          if(this.maininput != this.current) this.focus(this.maininput);     
    }.bind(this));
    this.makeResizable(this.maininput);
    this.setEvents();
  },
  
  setEvents: function() {
    document.observe(Prototype.Browser.IE ? 'keydown' : 'keypress', function(e) {      
      if(! this.current) return;
      if(this.current.retrieveData('type') == 'box' && e.keyCode == Event.KEY_BACKSPACE) e.stop();
    }.bind(this));      
         
    document.observe(
      'keyup', function(e) {
        e.stop();
        if(! this.current) return;
        switch(e.keyCode){
          case Event.KEY_LEFT: return this.move('left');
          case Event.KEY_RIGHT: return this.move('right');
          case Event.KEY_DELETE:
          case Event.KEY_BACKSPACE: return this.moveDispose();
        }
      }.bind(this)).observe(  
      'click', function() { document.fire('blur'); }.bindAsEventListener(this)
    );
  },
  
  update: function() {
    this.element.value = this.bits.values().join(this.options.get('separator'));
    return this;
  },
  
  add: function(text, html) {
    var id = this.options.get('className') + '-' + this.count++;
	// added option for qualifing the element to add as a new value
    var el = this.createBox($pick(html, text), {'id': id, 'newValue' : text.newValue ? 'true' : 'false'});
    (this.current || this.maininput).insert({'before':el});
    el.observe('click', function(e) {
      e.stop();
      this.focus(el);
    }.bind(this));
    this.bits.set(id, text.value);    
	// Dynamic updating... why not?
    this.update();
    if(this.options.get('extrainputs') && (this.options.get('startinput') || el.previous())) this.addSmallInput(el,'before');
    return el;
  },
  
  addSmallInput: function(el, where) {
    var input = this.createInput({'class': 'smallinput'});
    el.insert({}[where] = input);
    input.cacheData('small', true);
    this.makeResizable(input);
    if(this.options.get('hideempty')) input.hide();
    return input;
  },
  
  dispose: function(el) {
    this.bits.unset(el.id);
	// Dynamic updating... why not?
    this.update();
    if(el.previous() && el.previous().retrieveData('small')) el.previous().remove();
    if(this.current == el) this.focus(el.next());
    if(el.retrieveData('type') == 'box') el.onBoxDispose(this);
    el.remove();    
    return this;
  },
  
  focus: function(el, nofocus) {
    if(! this.current) el.fire('focus');
    else if(this.current == el) return this;
    this.blur();
    el.addClassName(this.options.get('className') + '-' + el.retrieveData('type') + '-focus');
    if(el.retrieveData('small')) el.setStyle({'display': 'block'});
    if(el.retrieveData('type') == 'input') {
      el.onInputFocus(this);      
      if(! nofocus) this.callEvent(el.retrieveData('input'), 'focus');
    }
    else el.fire('onBoxFocus');
    this.current = el;    
    return this;
  },
  
  blur: function(noblur) {
    if(! this.current) return this;
    if(this.current.retrieveData('type') == 'input') {
      var input = this.current.retrieveData('input');
      if(! noblur) this.callEvent(input, 'blur');   
      input.onInputBlur(this);
    }
    else this.current.fire('onBoxBlur');
    if(this.current.retrieveData('small') && ! input.get('value') && this.options.get('hideempty')) 
      this.current.hide();
    this.current.removeClassName(this.options.get('className') + '-' + this.current.retrieveData('type') + '-focus');
    this.current = false;
    return this;
  },
  
  createBox: function(text, options) {
    return new Element('li', options).addClassName(this.options.get('className') + '-box').update(text.caption).cacheData('type', 'box');
  },
  
  createInput: function(options) {
    var li = new Element('li', {'class': this.options.get('className') + '-input'});
    var el = new Element('input', Object.extend(options,{'type': 'text'}));
    el.observe('click', function(e) { e.stop(); }).observe('focus', function(e) { if(! this.isSelfEvent('focus')) this.focus(li, true); }.bind(this)).observe('blur', function() { if(! this.isSelfEvent('blur')) this.blur(true); }.bind(this)).observe('keydown', function(e) { this.cacheData('lastvalue', this.value).cacheData('lastcaret', this.getCaretPosition()); });
    var tmp = li.cacheData('type', 'input').cacheData('input', el).insert(el);
    return tmp;
  },
  
  callEvent: function(el, type) {
    this.events.set(type, el);
    el[type]();
  },
  
  isSelfEvent: function(type) {
    return (this.events.get(type)) ? !! this.events.unset(type) : false;
  },
  
  makeResizable: function(li) {
    var el = li.retrieveData('input');
    el.cacheData('resizable', new ResizableTextbox(el, Object.extend(this.options.get('resizable'),{min: el.offsetWidth, max: (this.element.getWidth()?this.element.getWidth():0)})));
    return this;
  },
  
  checkInput: function() {
    var input = this.current.retrieveData('input');
    return (! input.retrieveData('lastvalue') || (input.getCaretPosition() === 0 && input.retrieveData('lastcaret') === 0));
  },
  
  move: function(direction) {
    var el = this.current[(direction == 'left' ? 'previous' : 'next')]();
    if(el && (! this.current.retrieveData('input') || ((this.checkInput() || direction == 'right')))) this.focus(el);
    return this;
  },
  
  moveDispose: function() {
    if(this.current.retrieveData('type') == 'box') return this.dispose(this.current);
    if(this.checkInput() && this.bits.keys().length && this.current.previous()) return this.focus(this.current.previous());
  }
  
});

//helper functions 
Element.addMethods({
  getCaretPosition: function() {
    if (this.createTextRange) {
      var r = document.selection.createRange().duplicate();
        r.moveEnd('character', this.value.length);
        if (r.text === '') return this.value.length;
        return this.value.lastIndexOf(r.text);
    } else return this.selectionStart;
  },
  cacheData: function(element, key, value) { 
    if (Object.isUndefined(this[$(element).identify()]) || !Object.isHash(this[$(element).identify()]))
        this[$(element).identify()] = $H();
    this[$(element).identify()].set(key,value);
    return element;
  },
  retrieveData: function(element,key) {
    return this[$(element).identify()].get(key);
  }  
});

function $pick(){for(var B=0,A=arguments.length;B<A;B++){if(!Object.isUndefined(arguments[B])){return arguments[B];}}return null;}

/*
  Proto!MultiSelect 0.2
  - Prototype version required: 6.0
  
  Credits:
  - Idea: Facebook
  - Guillermo Rauch: Original MooTools script
  - Ran Grushkowsky/InteRiders Inc. : Porting into Prototype and further development
  
  Changelog:
  - 0.1: translation of MooTools script
  - 0.2: renamed from Proto!TextboxList to Proto!MultiSelect, added new features/bug fixes
        added feature: support to fetch list on-the-fly using AJAX    Credit: Cheeseroll
        added feature: support for value/caption
        added feature: maximum results to display, when greater displays a scrollbar   Credit: Marcel
        added feature: filter by the beginning of word only or everywhere in the word   Credit: Kiliman
        added feature: shows hand cursor when going over options
        bug fix: the click event stopped working
        bug fix: the cursor does not 'travel' when going up/down the list   Credit: Marcel
*/

/* Copyright: InteRiders <http://interiders.com/> - Distributed under MIT - Keep this message! */

var FacebookList = Class.create(TextboxList, { 
  
  initialize: function($super,element, autoholder, options, func) {
    $super(element, options);
	this.loptions = $H({    
	    autocomplete: {
	      'opacity': 0.8,
	      'maxresults': 10,
	      'minchars': 1
	    }
	});
    this.data = [];    
    this.autoholder = $(autoholder).setOpacity(this.loptions.get('autocomplete').opacity); 
    this.autoholder.observe('mouseover',function() {this.curOn = true;}.bind(this)).observe('mouseout',function() {this.curOn = false;}.bind(this));
    this.autoresults = this.autoholder.select('ul').first();
    var children = this.autoresults.select('li');
    children.each(function(el) { this.add({value:el.readAttribute('value'),caption:el.innerHTML}); }, this); 
  },
  
  autoShow: function(search) {
    this.autoholder.setStyle({'display': 'block'});
    this.autoholder.descendants().each(function(e) { e.hide() });
    if(! search || ! search.strip() || (! search.length || search.length < this.loptions.get('autocomplete').minchars)) 
    {
      this.autoholder.select('.default').first().setStyle({'display': 'block'});
      this.resultsshown = false;
    } else {
      this.resultsshown = true;
      this.autoresults.setStyle({'display': 'block'}).update('');
      if (this.options.get('wordMatch'))
        var regexp = new RegExp("(^|\\s)"+search,'i')
      else
        var regexp = new RegExp(search,'i')
      var count = 0;
      this.data.filter(function(str) { return str ? regexp.test(str.evalJSON(true).caption) : false; }).each(function(result, ti) {
        count++;
        if(ti >= this.loptions.get('autocomplete').maxresults) return;
        var that = this;
        var el = new Element('li');
        el.observe('click',function(e) { 
            e.stop();
            that.autoAdd(this); 
        }).observe('mouseover',function() { 
            that.autoFocus(this);
        }).update(this.autoHighlight(result.evalJSON(true).caption, search));
        this.autoresults.insert(el);
        el.cacheData('result', result.evalJSON(true));
        if(ti == 0) this.autoFocus(el);
      }, this);
    }
    if (count > this.options.get('results'))
        this.autoresults.setStyle({'height': (this.options.get('results')*24)+'px'});
    else
        this.autoresults.setStyle({'height': (count?(count*24):0)+'px'});
    return this;
  },
  
  autoHighlight: function(html, highlight) {
    return html.gsub(new RegExp(highlight,'i'), function(match) {
      return '<em>' + match[0] + '</em>';
    });
  },
  
  autoHide: function() {    
    this.resultsshown = false;
    this.autoholder.hide();    
    return this;
  },
  
  autoFocus: function(el) {
    if(! el) return;
    if(this.autocurrent) this.autocurrent.removeClassName('auto-focus');
    this.autocurrent = el.addClassName('auto-focus');
    return this;
  },
  
  autoMove: function(direction) {    
    if(!this.resultsshown) return;
    this.autoFocus(this.autocurrent[(direction == 'up' ? 'previous' : 'next')]());
    this.autoresults.scrollTop = this.autocurrent.positionedOffset()[1]-this.autocurrent.getHeight();         
    return this;
  },
  
  autoFeed: function(text) {
    if (this.data.indexOf(Object.toJSON(text)) == -1)
        this.data.push(Object.toJSON(text));
    return this;
  },
  
  autoAdd: function(el) {
    if(this.newvalue && this.options.get("newValues")) {
	  // If the added element is a new value (not found on the autocomplete list)
	  // we will wrap the value on brackets upon submission for easier identification
      this.add({caption: el.value, 
			value: this.options.get('newValueDelimiters')[0] + el.value + this.options.get('newValueDelimiters')[1], 
			newValue: true
	  });
      var input = el;
    } else if(!el || ! el.retrieveData('result')) {
      return;
    } else {
      this.add(el.retrieveData('result'));
      delete this.data[this.data.indexOf(Object.toJSON(el.retrieveData('result')))];
      var input = this.lastinput || this.current.retrieveData('input');
    }
    this.autoHide();
    input.clear().focus();
    return this;
  },
  
  createInput: function($super,options) {
    var li = $super(options);
    var input = li.retrieveData('input');
    input.observe('keydown', function(e) {
        this.dosearch = false;
		this.newvalue = false;
		
        switch(e.keyCode) {
          case Event.KEY_UP: e.stop(); return this.autoMove('up');
          case Event.KEY_DOWN: e.stop(); return this.autoMove('down');  
		  case Event.KEY_COMMA:
            if(this.options.get('newValues')) {
              new_value_el = this.current.retrieveData('input');
              new_value_el.value = new_value_el.value.strip().gsub(",","");
              if(!this.options.get("spaceReplace").blank()) new_value_el.gsub(" ", this.options.get("spaceReplace"));
              if(!new_value_el.value.blank()) {
                e.stop();
                this.newvalue = true;
                this.autoAdd(new_value_el);
              }
            }
            break;      
          case Event.KEY_RETURN:
            e.stop();
            if(! this.autocurrent) break;
            this.autoAdd(this.autocurrent);
            this.autocurrent = false;
            this.autoenter = true;
            break;
          case Event.KEY_ESC: 
            this.autoHide();
            if(this.current && this.current.retrieveData('input'))
              this.current.retrieveData('input').clear();
            break;
          default: this.dosearch = true;
        }
    }.bind(this));
    input.observe('keyup',function(e) {
        
        switch(e.keyCode) {
          case Event.KEY_UP: 
          case Event.KEY_DOWN: 
          case Event.KEY_RETURN:
          case Event.KEY_ESC: 
            break;              
          default: 
                if (!Object.isUndefined(this.options.get('fetchFile'))) {
                  new Ajax.Request(this.options.get('fetchFile'), {
                    parameters: {keyword: input.value},
                    onSuccess: function(transport) {
                        transport.responseText.evalJSON(true).each(function(t){this.autoFeed(t)}.bind(this));
                        this.autoShow(input.value);
                    }.bind(this)
                  });        
                }
                else
                    if(this.dosearch) this.autoShow(input.value);          
        }        
    }.bind(this));
    input.observe(Prototype.Browser.IE ? 'keydown' : 'keypress', function(e) { 
      if(this.autoenter) e.stop();
      this.autoenter = false;
    }.bind(this));
    return li;
  },
  
  createBox: function($super,text, options) {
    var li = $super(text, options);
    li.observe('mouseover',function() { 
        this.addClassName('bit-hover');
    }).observe('mouseout',function() { 
        this.removeClassName('bit-hover') 
    });
    var a = new Element('a', {
      'href': '#',
      'class': 'closebutton'
      }
    );
    a.observe('click',function(e) {
          e.stop();
          if(! this.current) this.focus(this.maininput);
          this.dispose(li);
    }.bind(this));
    li.insert(a).cacheData('text', Object.toJSON(text));
    return li;
  }
  
});

Element.addMethods({
    onBoxDispose: function(item,obj) { 
	    // Set to not to "add back" values in the drop-down upon delete if they were new values
		item = item.retrieveData('text').evalJSON(true);
		if(!item.newValue)
	    	obj.autoFeed(item); 
	  },
    onInputFocus: function(el,obj) { obj.autoShow(); },    
    onInputBlur: function(el,obj) { 
        obj.lastinput = el;
        if(!obj.curOn) {
            obj.blurhide = obj.autoHide.bind(obj).delay(0.1);
        }
    },
    filter:function(D,E){var C=[];for(var B=0,A=this.length;B<A;B++){if(D.call(E,this[B],B,this)){C.push(this[B]);}}return C;}
});