# Copyright (C) 2009 Pascal Rettig.


# Provides a tag for embedding sparklines graphs into your Rails app.
#
# To use, load it in your controller with
#
#   helper :sparklines
#
# AUTHOR
#
# Geoffrey Grosenbach[mailto:boss@topfunky.com]
#
# http://topfunky.com
# 
# License
#
# This code is licensed under the MIT license.
#
module SparklinesHelper

	# Call with an array of data and a hash of params for the Sparklines module.
	# You can also pass :class => 'some_css_class' ('sparkline' by default).
	def sparkline_tag(results=[], options={}, html={})		
		url = { :controller => '/sparklines',
		        :action => 'index',
			:results => results.join(',') }
		options = url.merge(options)
		
		html[:src] = url_for(options)
		tag("img",html)
		#"<img src=\"#{ url_for options }\" class=\"#{options[:class] || 'sparkline'}\" alt=\"Sparkline Graph\" />"
	end

end
