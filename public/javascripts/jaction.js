
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
      },
      loader: function(sel) {
         var settings = sel.split(",");
         var elem = $j(settings[0]).first();
         var url = settings[1];
         var refresh = settings.length > 2 ? settings[2] == 'true' : false;
         var refreshContent = refresh ? elem.html() : '';
         $j(this).click(function() {
           if(! elem.attr('j-loaded') || refresh) {
             if(elem.attr('j-loaded') && refresh) { elem.html(refreshContent); }
             elem.attr('j-loaded', 1);
             if(! elem.attr('j-loading')) {
               elem.attr('j-loading', 1);
               elem.load(url, function() { elem.removeAttr('j-loading'); });
             }
           }
         });
      }
  }

  JClick = {
      slideup: function() { this.slideUp(); },
      slidetoggle: function() { this.slideToggle(); },
      openclose: function() { this.toggle(); }
  }

  JForm = {
      updateform: function(sel) {
        var settings = sel ? sel.split(",") : [];
        var url = settings.length > 0 ? settings[0] : document.location.pathname;
        var container = settings.length > 1 ? $j(settings[1]) : $j(this[0].form).parent();
        var frm = settings.length > 2 ? $j(settings[2]) : $j(this[0].form);
        $j(this[0]).change(function() {
          container.load(url, frm.serializeArray());
        });
      },

      submitform: function(sel) {
        var settings = sel ? sel.split(",") : [];
        var url = settings[0];
        var frm = $j(this[0]);
        var container = settings.length > 1 ? $j(settings[1]) : frm.parent();

        $j(this[0]).submit(function() {
          var data = frm.serializeArray();
          data.push({name: 'commit', value: 1});
          $j.post(url, data, function(res, status, xhr) {
            var contentType = xhr.getResponseHeader("Content-Type");
            if(!(contentType && contentType.match(/^\s*(text|application)\/(x-)?(java|ecma)script(;.*)?\s*$/i))) {
              container.html(res);
            }
          });
          return false;
        });
      }
  }

  JSetup = {
      setup: function() {
        $j("*[j-action]").each(function() {
          var elem = $j(this);
          var acts = elem.attr('j-action').split(",");
          var act_length = acts.length;

          for(var i = 0;i< act_length;i++) {
            if(JAction[acts[i]]) {
              var actfield = acts[i];
              var sel = $j(elem).attr(actfield);
              JAction[acts[i]].call(elem,sel);
            } else if(JForm[acts[i]]) {
              var actfield = acts[i];
              var sel = $j(elem).attr(actfield);
              JForm[acts[i]].call(elem,sel);
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
          elem.removeAttr('j-action');
        });
      }
  }

  $j(document).ready(function() { JSetup.setup(); });

