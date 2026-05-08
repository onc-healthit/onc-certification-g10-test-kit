# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

#Filler gems to be replaced with git dependencies in the gemspec for development and testing purposes. These should not be used in production environments and will need to be replaced once these gems come out.
gem 'inferno_core', git: 'https://github.com/FlexonyoPizza/inferno-core.git', branch: 'main'
gem 'us_core_test_kit', git: 'https://github.com/FlexonyoPizza/us-core-test-kit.git', branch: 'main'
gem 'smart_app_launch_test_kit', git: 'https://github.com/FlexonyoPizza/smart-app-launch-test-kit.git', branch: 'main'
gem 'tls_test_kit', git: 'https://github.com/FlexonyoPizza/tls-test-kit.git', branch: 'main'

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
