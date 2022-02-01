Gem::Specification.new do |spec|
  spec.name          = 'g10_certification_test_kit'
  spec.version       = '0.0.1'
  spec.authors       = ['Stephen MacVicar']
  spec.email         = ['inferno@groups.mitre.org']
  spec.summary       = 'G10 Certification Tests for Inferno'
  spec.description   = 'G10 Certification Tests for Inferno'
  spec.homepage      = 'https://github.com/inferno_framework/g10-certification-test-kit'
  spec.license       = 'Apache-2.0'
  spec.add_runtime_dependency 'inferno_core', '~> 0.1.2'
  spec.add_runtime_dependency 'bloomer', '~> 1.0.0'
  spec.add_runtime_dependency 'colorize', '~> 0.8.1'
  spec.add_development_dependency 'database_cleaner-sequel', '~> 1.8'
  spec.add_development_dependency 'factory_bot', '~> 6.1'
  spec.add_development_dependency 'rspec', '~> 3.10'
  spec.add_development_dependency 'webmock', '~> 3.11'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.7.0')
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/inferno_framework/g10-certification-test-kit'
  spec.files = [
    Dir['lib/**/*.rb'],
    Dir['lib/**/*.json'],
    'LICENSE'
  ].flatten

  spec.require_paths = ['lib']
  spec.metadata = {
    'rubygems_mfa_required' => 'true'
  }
end
