require_relative 'resource_access_test'

module G10CertificationTestKit
  class RestrictedAccessTest < ResourceAccessTest
    id :g10_restricted_access_test
    input :expected_resources

    def request_should_succeed?
      expected_resources.split(',').any? { |resource| resource.strip.casecmp? resource_type }
    end
  end
end
