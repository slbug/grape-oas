# frozen_string_literal: true

require "grape"
require "zeitwerk"

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  "grape-oas" => "GrapeOAS",
  "grape_oas" => "GrapeOAS",
)
loader.ignore("#{__dir__}/grape-oas.rb")
loader.setup

module GrapeOAS
  class Error < StandardError; end
  # Your code goes here...
end
