require_relative 'lib/onc_certification_g10_test_kit/version'

Gem::Specification.new do |spec|
  spec.name          = 'onc_certification_g10_test_kit'
  spec.version       = ONCCertificationG10TestKit::VERSION
  spec.authors       = ['Stephen MacVicar']
  spec.email         = ['inferno@groups.mitre.org']
  spec.summary       = 'ONC Certification (g)(10) Test Kit'
  spec.description   = 'ONC Certification (g)(10) Standardized API for Patient and Population Services Test Kit'
  spec.homepage      = 'https://github.com/onc-healthit/onc-certification-g10-test-kit'
  spec.license       = 'Apache-2.0'
  spec.add_dependency 'bloomer', '~> 1.0.0'
  spec.add_dependency 'colorize', '~> 0.8.1'
  spec.add_dependency 'inferno_core', '~> 0.6.2'
  spec.add_dependency 'json-jwt', '~> 1.15.3'
  spec.add_dependency 'mime-types', '~> 3.4.0'
  spec.add_dependency 'ndjson', '~> 1.0.0'
  spec.add_dependency 'rubyzip', '~> 2.3.2'

  # **Please note**: Version constraints for dependant test kits should only be
  # locked to a single version in certification test kits (such as this one).
  # All other test kits should use more flexible version constraints to avoid
  # conflicts when integrating into platforms (e.g.; inferno.healthit.gov).
  spec.add_dependency 'smart_app_launch_test_kit', '0.5.1'
  spec.add_dependency 'tls_test_kit', '0.3.0'
  spec.add_dependency 'us_core_test_kit', '0.10.1'

  spec.required_ruby_version = Gem::Requirement.new('>= 3.3.6')
  spec.metadata['inferno_test_kit'] = 'true'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.files = `[ -d .git ] && git ls-files -z lib config/presets LICENSE`.split("\x0")

  spec.require_paths = ['lib']
end
