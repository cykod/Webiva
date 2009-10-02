# Copyright (C) 2009 Pascal Rettig.


module EscapeHelper

  include  ActionView::Helpers::JavaScriptHelper
  
  def uri_escape(txt)
    URI.escape(txt, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
  end

   def jvh(txt)
     #escape_javascript(txt.to_s).gsub('<','\u003C')
     txt.gsub("&amp;","&#34;").gsub("'","&#39;").gsub('"',"&#34;").gsub('<','\u003C').gsub("\n","\\n")

   end

   def jh(txt)
    escape_javascript(txt.to_s).gsub('<','\u003C')
   end
   
   def vh(txt)
    h_escape(txt).gsub("'","&#39;").gsub('"',"&quot;")
   end
   
   def qvh(txt)
    txt.gsub("'","&#39;").gsub('"',"&quot;")
   end

    def h_escape(s)
      s.to_s.gsub(/&/, "&amp;").gsub(/\"/, "&quot;").gsub(/>/, "&gt;").gsub(/</, "&lt;")
    end


end
