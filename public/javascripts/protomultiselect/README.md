# Proto!MultiSelect

Prototype version required: 6.0

Copyright: InteRiders <http://interiders.com/> - Distributed under MIT - Keep this message!
  
## Credits

 - Idea: Facebook + Apple Mail
 - Caret position method: Diego Perini <http://javascript.nwbox.com/cursor_position/cursor.js>
 - Guillermo Rauch: Original MooTools script
 - Ran Grushkowsky/InteRiders Inc. <http://interiders.com/> 
 - Loren Johnson, <http://www.hellovenado.com/>
 - Zuriel Barron, <http://severelimitation.com/>
 - Sean Cribbs <http://seancribbs.com/>
 - [skaue]
 - Nickolas Daskalou <http://www.footysx.com.au/>
 - Chris Anderton <http://thewebfellas.com/>
 - Dejan Strbac

## Parameters (and defaults)

 - separator: ','
 - extrainputs: true
 - startinput: true
 - hideempty: true
 - newValues: false 
   - allow new values to be created
 - newValueDelimiters: ['[',']']
   - define what values split into new entries
 - spaceReplace: ''
   - allow handling of new tag values when the tagging scheme doesn't allow spaces, this is set as blank by default and will have no impact
 - fetchFile: undefined,
   - location of JSON file
 - fetchMethod: 'get'
   - set HTTP method
 - results: 10,
   - maximum number of results to retrieve for display in the list (see also maxResults)
 - maxResults: 0
   - number of results to show in the list before scrolling  - when set to 0 then it uses the default of 10 (i.e. there is no 'zero' option)
 - wordMatch: false
   - when set to true will match only the beginning of word (only when using regex search), otherwise will match anywhere
 - onEmptyInput: function(input){}
   - callback that is called when user hits enter when the input is blank
 - caseSensitive: false
   - case sensitive/insensitive matching
 - regexSearch: true
   - specifies whether to search using a regular expression or simple text search (faster)

## Changelog

### 0.1
  - translation of MooTools script

### 0.2
  - renamed from Proto!TextboxList to Proto!MultiSelect, added new features/bug fixes
  - added feature: support to fetch list on-the-fly using AJAX    Credit: Cheeseroll
  - added feature: support for value/caption
  - added feature: maximum results to display, when greater displays a scrollbar   Credit: Marcel
  - added feature: filter by the beginning of word only or everywhere in the word   Credit: Kiliman
  - added feature: shows hand cursor when going over options
  - bug fix: the click event stopped working
  - bug fix: the cursor does not 'travel' when going up/down the list   Credit: Marcel

### 0.3
  - bug fix: moved class variables into initialize so they happen per instance. This allows multiple controls per page
  - bug fix: added id_base attribute so that multiple controls on the same page have unique list item ids (won't work otherwise)
  - feature: Added newValues option and logic to allow new values to be created when ended with a comma (tag selector use case)           
  - mod: removed ajax fetch file happening on every search and moved it to initialization to laod all results immediately and not keep polling
  - mod: added "fetchMethod" option so I could better accomodate my RESTful ways and set a "get" for retrieving
  - mod: added this.update to the add and dispose methods to keep the target input box values always up to date
  - mod: moved ResizableTextBox, TextBoxList and FaceBookList all into same file
  - mod: added extra line breaks and fixed-up some indentation for readability
  - mod: spaceReplace option added to allow handling of new tag values when the tagging scheme doesn't allow spaces, this is set as blank by default and will have no impact

### 0.4 
  - bug fix: fixed bug where it was not loading initial list values
  - bug fix: new values are not added into the autocomplete list upon removal
  - bug fix: improved browser compatibility (Safari, IE)
  
### 0.5
  - Add search timeout to increase responsiveness to typing.
  - Add non-standard autocomplete attribute to main input to prevent browser-supplied autocompletion in Gecko and some other browsers.
  - bug when gsub'ing space wth "spaceReplace". Input-field does not have a function gsub, though its value has.
  
### 0.6
  - Update with changes by Nickolas Daskalou
  - Option to specify whether to perform a case sensitive search or not (option: "caseSensitive", default: false).
  - Option to specify whether you want the search to be performed by regular expression or by simple text search (option: "regexSearch", default: true). Non-regular expression searching is MUCH faster than by regular expression (this is the way the real Facebook autocomplete search works).
  - Option to specify a callback upon the user hitting Enter/Return when the input is blank (option: "onEmptyInput", default: function(){}). I needed this because I did not want the user to have to move their hand off the keyboard to the mouse and then click on the submit/action button.
  - Option to specify the maximum number of results to show (NOT the same as the "result" option, see comments below) (option: "maxResults", default: 10).
  - NOTE ON THE NON-REGULAR EXPRESSION SEARCH: If using non-regular expression search mode, the option "matchWord" WILL HAVE NO EFFECT on the results (ie., it will behave as if matchWord were set to false). This can be fixed but at 5am my pillow is looking too good to spend more time on this, so if anyone needs this feel free to email me a request and I'll get it done (nick at footysx.com.au).
  - NOTE ON THE MAXRESULTS OPTION: The difference between the options "results" and "maxResults" is that "results" specifies the maximum number of visible rows allowed to be shown to the user before a scrollbar activates, whereas "maxResults" specifies the maximum number of results allowed to be in the scrollable list.

### 0.7
  - fixed non regex search
  - stable
  
### 0.8
  - a number of updates provided by Dejan Strbac
  - sanitizes characters so special characters don't break it
  - escapes html