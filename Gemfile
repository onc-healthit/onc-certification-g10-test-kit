# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem 'smart_app_launch_test_kit', git: 'https://github.com/inferno-framework/smart-app-launch-test-kit.git', branch: 'id45-execution-scripts'
gem 'us_core_test_kit', git: 'https://github.com/inferno-framework/us-core-test-kit.git', branch: 'id45-execution-scripts'


group :development, :test do
  gem 'debug'
  gem 'rubocop', '~> 1.9'
  gem 'rubocop-rspec', require: false
  gem 'rubyXL'
  gem 'rack-test'
  gem 'selenium-webdriver'
end

group :test do
  gem 'database_cleaner-sequel'
  gem 'factory_bot', '~> 6.1'
  gem 'rspec', '~> 3.10'
  gem 'webmock', '~> 3.11'
end
