# Copyright (C) 2009 Pascal Rettig.


# Utility class for outputing formatted text.
class Util::TextFormatter

  # Generate formatted text from html
  def  self.text_formatted_generator(html)
    sanitizer = HTML::FullSanitizer.new
    html = self.unescape_html html
    html = html.gsub(/<(h[1-5]).*?>(.*?)<\/\1>/mi) do |mtch|
      str = self.strip_white_space(sanitizer.sanitize($2).gsub("\n", ' '))
      "\n#{str}\n#{'=' * str.length}\n\n"
    end
    html = sanitizer.sanitize html
    self.strip_white_space html
  end

  # Generate plan text from html
  def self.text_plain_generator(html)
    html = self.unescape_html html
    html = HTML::FullSanitizer.new.sanitize html
    self.strip_white_space html
  end

  # Return a fixed-width text friendly table
  def self.text_table(columns,data)
    column_widths = []

    # Initial Width is columns    
    columns.each_with_index { |col,idx| column_widths[idx] = col.length }
    
    data.each_with_index do |row,row_idx|
      row.each_with_index do |col,col_idx|
        col_data = col.split("\n")
        col_data.each do |col_entry|
          column_widths[col_idx] = col_entry.length if column_widths[col_idx] < col_entry.length
        end
      end
    end
    
    # Total width = width of columns + 2 extra spaces + extra | for each column + initial |
    total_width = column_widths.inject(0) { |tot,elm| tot+=elm } + 3 * columns.length + 1
    
    output = [ "-" * total_width ]
    output << text_table_row(column_widths,columns)
    output << output[0]
    data.each { |row| output += text_table_row(column_widths,row) }
    output << output[0]
    output.join("\n") + "\n"
  end
  
  # generate a html table from data (for inserting into email etc)
  def self.html_table(columns,data,atr={})
    attributes = ""
    atr.each { |key,val| attributes += " #{key}='#{val}'" }
  
    output = "<table#{attributes}><thead><tr>"
    output += columns.map { |col| "<th>#{col}</th>" }.join("")
    output += "</tr></thead><tbody>"
    output += data.map { |row| "<tr>" + row.map { |elm| "<td>#{elm}</td>"}.join + "</tr>" }.join
    output += "</tbody></table>"
    
    output
  end

  def self.unescape_html(html)
    CGI::unescapeHTML html.to_s.gsub(/<\/(p|div)>/i," </\\1>\n ").gsub(/<br.*?>/i,"\n").gsub(/&nbsp;/i," ")
  end
  
  def self.strip_white_space(str)
    # \xC2\xA0 non-breaking space
    str.strip.gsub("\xC2\xA0", ' ').gsub(/[ \t]+/, ' ').split("\n").map(&:strip).join("\n").gsub(/\n\n\n+/, "\n\n")
  end

  protected
  
  def self.text_table_row(column_widths,columns) #:nodoc: 
    extra_row = nil
    output = "|"
    column_widths.each_with_index do |col_width,idx|
      col = columns[idx]
      col ||= ''
      # Make sure we handle multi line data rows
      col_data = col.split("\n")
      col_data = [ "" ] if col_data.length == 0
      if col_data.length > 1
        extra_row ||=  []
        extra_row[idx] = col_data[1..-1].join("\n")
      end
      col_data = col_data[0]
      
      right_buffer = 1 + (column_widths[idx] - col_data.length)
      output += " #{col_data}#{' ' * right_buffer}|"
    end
    if extra_row
      [ output ] + text_table_row(column_widths,extra_row)
    else
      [ output ]
    end
  end

end
