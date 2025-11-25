# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

Bundler.setup :default, :test

require "minitest/autorun"
require "minitest/pride" if ENV["PRIDE"]

require "rack"
require "rack/test"
require "dry-schema"  # Must be loaded before grape for contract support
require "grape"
require "grape-entity"
require "grape-oas"

# Load support files
Dir[File.expand_path("support/**/*.rb", __dir__)].each { |f| require f }
