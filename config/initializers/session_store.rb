# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key    => '_Webiva_session',
  :secret => '322ae3dea0aefdede19e2545b4f9446c982887bb3793400c7b4895938f09ff737f3a7c33a251eeba9bbe502f3fbd1aa06d2ee0f5caeb14c7004c7f9d65734a99'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
