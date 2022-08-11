# License: AGPL-3.0-or-later WITH WTO-AP-3.0-or-later
# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
Commitchange::Application.config.secret_token = ENV.fetch('SECRET_TOKEN')

Commitchange::Application.config.secret_key_base = ENV.fetch('SECRET_KEY_BASE')
