# Copyright (C) 2009 Pascal Rettig.


module EscapeHelper

  include  ActionView::Helpers::JavaScriptHelper
  
  def uri_escape(txt)
    URI.escape(txt, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
  end

   def jvh(txt)
     #escape_javascript(txt.to_s).gsub('<','\u003C')
     txt.gsub("&amp;","&#34;").gsub("'","&#39;").gsub('"',"&#34;").gsub('<','\u003C').gsub("\n","\\n").gsub("\xE2\x80\xA8", '\u2028').gsub("\xE2\x80\xA9", '\u2029')

   end

   def jh(txt)
    escape_javascript(txt.to_s).gsub('<','\u003C').gsub("\xE2\x80\xA8", '\u2028').gsub("\xE2\x80\xA9", '\u2029')
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
