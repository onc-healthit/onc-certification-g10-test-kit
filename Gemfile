# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# rc1 has been released, but don't want to risk updating the day of our release
gem 'hanami-utils', '2.0.0.beta1'

gem 'smart_app_launch_test_kit',
    git: 'https://github.com/inferno-framework/smart-app-launch-test-kit.git',
    branch: 'release-030'

group :development, :test do
  gem 'rubocop', '~> 1.9'
  gem 'rubocop-rspec', require: false
  gem 'rubyXL'
  gem 'debug'
end
