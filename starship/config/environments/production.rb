# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true
config.action_view.cache_template_loading            = true

config.log_level = :debug

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host                  = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false

# Authentication:
# Starship can either authenticate against Novell iChain or use basic
# auth, which can be be configured with various sources through the
# webserver
# Parameter: AUTHENTICATION
# set this parameter to either
# :simulate => means the user is hardcoded to termite
# :ichain   => iChain is used.
# :off      => basic auth
AUTHENTICATION = :ichain

