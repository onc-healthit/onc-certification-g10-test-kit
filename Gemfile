# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# TODO: remove once once a version of sidekiq above 6.5.5 is released. Redis
# 4.8.0 causes excessive deprecation warnings
gem 'redis', '4.7.1'

group :development, :test do
  gem 'rubocop', '~> 1.9'
  gem 'rubocop-rspec', require: false
  gem 'rubyXL'
end
