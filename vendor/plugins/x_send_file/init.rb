require 'x_send_file'

# Add x_send_file to ActionController
ActionController::Base.send(:include, XSendFile::Controller)