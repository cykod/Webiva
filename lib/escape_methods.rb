# Copyright (C) 2009 Pascal Rettig.

module EscapeMethods

 def jvh(txt)
    txt.gsub("'","&apos;").gsub('"',"&quot;")
   end

   def vh(txt)
    h(txt).gsub("'","&apos;").gsub('"',"&quot;")
   end
   
    def h(s)
      s.to_s.gsub(/&/, "&amp;").gsub(/\"/, "&quot;").gsub(/>/, "&gt;").gsub(/</, "&lt;")
    end

  
end
