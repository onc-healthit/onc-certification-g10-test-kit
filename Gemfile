# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem 'us_core_test_kit',
    git: 'git@github.com:inferno-framework/us-core-test-kit.git',
    branch: 'main'

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
