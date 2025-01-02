# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem 'inferno_core', path: '../inferno'
gem 'smart_app_launch_test_kit', path: '../smart-app-launch-test-kit'
gem 'us_core_test_kit', path: '../us-core-test-kit'

group :development, :test do
  gem 'debug'
  gem 'rubocop', '~> 1.9'
  gem 'rubocop-rspec', require: false
  gem 'rubyXL'
   gem 'rack-test'
end

group :test do
  gem 'database_cleaner-sequel'
  gem 'factory_bot', '~> 6.1'
  gem 'rspec', '~> 3.10'
  gem 'webmock', '~> 3.11'
end
