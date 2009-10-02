# Copyright (C) 2009 Pascal Rettig.

module HtmlExtractor

  def html_extract_text(source)
    #ignore the following:
    ignore = [ '&gt;', '&gt;&gt;','&lt;&lt;','&nbsp;', '&nbsp;&nbsp;', '']
    
    # We start off in text area
    # Find the next, <, {, or end of document

    lines = []
  
    md = '';
    pos = 0;
    endpos = 0;
    srcLen = source.length
    while(pos < srcLen) 
      lt = source.index("<",pos)
      if(lt != nil) 
        endpos = lt-1;
        md='<';
      else
        endpos = srcLen-1;
        md='end';
      end
      
      if(endpos >= pos) 
        txt = source[pos..endpos];
        ttxt = txt.strip
        if !ignore.include?(ttxt) && ttxt.length > 1 && !(ttxt =~ /^([[:punct:][:space:]]*)$/m)
          lines << ttxt
        end
      end
      
      tagpos = endpos+1;
      pos = endpos + 2;
    
      if md == '<'
        if source[lt..(lt+7)] == '<script'
          newpos = source.index("</script>",pos) + 9
          if(newpos === nil)
            pos = srcLen
          else
            pos = newpos;
          end
        elsif source[lt...(lt+6)] == '<style' 
          newpos = source.index("</style>",pos) + 9;
          if(newpos === nil)
            pos = srcLen
          else
            pos = newpos;
          end
        else
          newpos = html_extract_close_token(source,">",pos);
          if(newpos === nil)
            pos = srcLen
          else
            pos = newpos
          end
        end
      end
    end
    
    return lines
  end
  
  
  private 
  def html_extract_close_token(source,chr,pos) 
    sqt = 0;
    dbl = 0;
    ok = false
    while  !ok 
      close_pos  = source.index(chr,pos)
      return nil if(close_pos === nil)
        
      if(close_pos > pos) 
        trial_str = source[pos..(close_pos-pos)]
        i=0
        while(i < trial_str.length)
          tChr = trial_str[i]
          case tChr
            when '\\';  i+=1
            when "'"; sqt+=1
            when '"'; dbl+=1
            end
            i+=1
        end
        if((sqt % 2 == 0) && (dbl % 2 == 0))
            ok = true;
        else 
            pos = close_pos+1;
        end
      else 
        return nil
      end
    end
    return close_pos+1;
  end

end