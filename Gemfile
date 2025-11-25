# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "bundler", "~> 2.0"

gem "grape", path: ENV.fetch("GRAPE_PATH", "../grape")

gem "grape-entity"
gem "dry-schema"
gem "dry-validation"

group :development, :test do
  gem "debug"
  gem "rack"
  gem "rack-test"
  gem "rake"
  gem "rubocop", require: false
  gem "rubocop-minitest", require: false
end
