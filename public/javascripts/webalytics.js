(function() {
   var loc = document.createElement('script');
   str = '/webalytics?';
   var cloc = google.loader.ClientLocation;
   if (cloc  == null) { str += 'loc[country]=UN'  }
   else {
     str += 'loc[city]='+encodeURIComponent(cloc.address.city);
     str += '&loc[region]='+encodeURIComponent(cloc.address.region);
     str += '&loc[country]='+encodeURIComponent(cloc.address.country_code);
     str += '&loc[latitude]='+encodeURIComponent(cloc.latitude);
     str += '&loc[longitude]='+encodeURIComponent(cloc.longitude);
   }
   loc.src = str;
   document.documentElement.firstChild.appendChild(loc);
 })();

