

module CmsHelper


  def webiva_search_widget
    form_tag({ :controller => '/search'},:style => 'display:inline;') +
<<-SEARCH_WIDGET
  <input type='text' name='search' size='20' id='search_widget' value='Search Webiva' />
  
  <div class='autocomplete' id='search_widget_autocomplete' style='display:none; width:500px;'>
     <ul class="autocomplete_list">
       <li class='autocomplete_item' id='result_1'>
         <div class="name">Enter a colon (:) to see registered search handlers</div>
         <div class="subtext">Search handlers let you search different pieces of your Webiva Site</div>
       </li>
       <li class='autocomplete_item' id='result_1'>
         <div class="name">Enter a url to jump to a page of your site</div>
         <div class="subtext">The system will show pages that match the prefix you've entered</div>
       </li>
       <li class='autocomplete_item' id='result_1'>
         <div class="name">Or enter search terms to search content</div>
         <div class="subtext">The system will show site content that matches your search</div>
       </li>
    </ul>
 </div>
 
    <script>
      SearchWidget = {
       onFocus: function() {
          if(this.value=="Search Webiva") this.value=""; 
          SearchWidget.autocomplete.updateChoices($('search_widget_autocomplete').innerHTML);
          SearchWidget.autocomplete.hasFocus = true;
          SearchWidget.autocomplete.changed = false;
          SearchWidget.autocomplete.show();
       },
       onBlur: function() {
         if(this.value=="") this.value="Search Webiva"; 
      },
       setup: function() {
          $('search_widget').onfocus = SearchWidget.onFocus;
          $('search_widget').onblur = SearchWidget.onBlur;

          SearchWidget.autocomplete = new Ajax.Autocompleter('search_widget','search_widget_autocomplete','#{url_for(:controller => '/search', :action => 'autocomplete')}',
        { minChars: 1, frequency: 0.5, paramName: 'search', 
         afterUpdateElement: function(text,li) { 
           var url = li.select(".autocomplete_url");
           var text = li.select(".autocomplete_text");
        if(url[0]) {
           document.location = url[0].value;
          $('search_widget').value = li.select(".name")[0].innerHTML; 
        } else if(text[0]) {
          $('search_widget').value = text[0].value; 
          return false;
        }
        else {
          $('search_widget').value = li.select(".name")[0].innerHTML; 
        }
        },
        onShow: function(element,update) {
        if(!update.style.position || update.style.position=='absolute') {
          update.style.position = 'absolute';
          Position.clone(element, update, {
            setHeight: false,
            setWidth: false,
            offsetTop: element.offsetHeight
          });
          update.style.left = '';
          update.style.right = '0px';
        }
        Effect.Appear(update,{duration:0.15});
       }
      });
      shortcut.add("Alt+S",function() { $('search_widget').focus(); });
  

     }
     };
    

     SearchWidget.setup();
    </script> 
    </form>
SEARCH_WIDGET
  end
end
