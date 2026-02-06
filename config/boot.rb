ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.

# Load .env file in development/test
require "dotenv/load" if %w[development test].include?(ENV.fetch("RAILS_ENV", "development"))
