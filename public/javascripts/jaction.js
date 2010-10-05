
  JAction = { 
     swap: function(sel) {
       var show_hide = sel.split(",");
       $j(this).click(function() {
          $j(show_hide[0]).show();
          $j(show_hide[1]).hide();
        });
      },
      toggler: function(sel) {
        var show_hide = sel.split(",");
        $j(this).hover(function() {
          $j(show_hide[0]).show();
          $j(show_hide[1]).hide();
        }, function() { 
          $j(show_hide[1]).show();
          $j(show_hide[0]).hide();
        });
       },
       change: function(sel) {
         var settings = sel.split(",");
         var elem = settings[0];
         var value = settings[1];
         var show = settings.length > 2 ? settings[2] : 'show';
         var hide = settings.length > 3 ? settings[3] : 'hide';
         if($j(this).val() == value) { $j(elem)[show](); } else { $j(elem)[hide](); }
         $j(this).change(function() {
           if($j(this).val() == value) { $j(elem)[show](); } else { $j(elem)[hide](); }
         });
       }
  }

  JClick = {
      slideup: function() { this.slideUp(); },
      slidetoggle: function() { this.slideToggle(); }
  }

  $j(document).ready(function() {
     $j("*[j-action]").each(function() {
        var elem = $j(this);
        var acts = elem.attr('j-action').split(",");
        var act_length = acts.length;

        for(var i = 0;i< act_length;i++) {
          if(JAction[acts[i]]) {
            var actfield = acts[i];
            var sel = $j(elem).attr(actfield);
            JAction[acts[i]].call(elem,sel);
          }
          else if(JClick[acts[i]]) {
            (function(actfield) {
               $j(elem).click(function() {
                 var sel = $j(elem).attr(actfield);
                 JClick[actfield].apply($j(sel));
                });
             })(acts[i]);
           }
        }
    });
  });

