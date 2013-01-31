ActionController::Base.param_parsers.delete(Mime::XML) 
# https://groups.google.com/forum/m/#!topic/rubyonrails-security/61bkgvnSGTQ/discussion
#
#https://groups.google.com/forum/#!topic/rubyonrails-security/1h2DR63ViGo
ActiveSupport::JSON.backend = "JSONGem" 
