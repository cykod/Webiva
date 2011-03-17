# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
Webiva::Application.configure do
  config.secret_token = 'cf2854812278145761d6d0e95a8d429cbdd1516f7a852997a33d4fb8b7510882e7bc5d59b229ffafaf9cf9ec48bd6674692cb3f750616a501f46b122cb785673'
end
