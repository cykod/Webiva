# Copyright (c) 2007 John Guenin <john@guen.in>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

module XSendFile
  class Plugin    
    @@options = {
      :header => 'X-Sendfile',
      :render => { :nothing => true }
    }
    
    # A class attribute that holds the default options for all x_send_file method calls.
    # Set anything here that you normally pass to x_send_file or send_file as an option.
    cattr_accessor :options
    
    # Replaces Rails' built-in send_file method with x_send_file.  Use with caution!
    # The normal send_file method can still be accessed using send_file_without_xsendfile.
    def self.replace_send_file!
      ActionController::Base.send(:alias_method_chain, :send_file, :x_send_file)
    end
  end
end