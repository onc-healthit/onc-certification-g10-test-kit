module ONCCertificationG10TestKit
  class LimitedScopeGrantTest < Inferno::Test
    title 'OAuth token exchange response grants scope that is limited to those selected by user'
    description %(
      The ONC certification criteria requires that patients are capable of
      choosing which FHIR resources to authorize to the application. For this
      test, the tester specifies which resources will be selected during
      authorization, and this verifies that only those resources are granted
      according to the scopes returned during the access token response.
    )
    id :g10_limited_scope_grant

    input :received_scopes, :expected_resources

    def possible_resources
      [
        'AllergyIntolerance',
        'CarePlan',
        'CareTeam',
        'Condition',
        'Device',
        'DiagnosticReport',
        'DocumentReference',
        'Goal',
        'Immunization',
        'MedicationRequest',
        'Observation',
        'Procedure',
        'Patient'
      ]
    end

    def scope_granting_access?(resource_type, scopes)
      scopes.any? do |scope|
        scope.start_with?("patient/#{resource_type}", 'patient/*') && scope.end_with?('*', 'read')
      end
    end

    run do
      expected_resources_list = expected_resources.split(',').map(&:strip).map(&:downcase)
      allowed_resources =
        possible_resources.select { |resource_type| expected_resources_list.include? resource_type.downcase }
      forbidden_resources = possible_resources - allowed_resources

      received_scope_list = received_scopes.split

      improperly_granted_resources =
        forbidden_resources.select { |resource_type| scope_granting_access?(resource_type, received_scope_list) }
      improperly_denied_resources =
        allowed_resources.reject { |resource_type| scope_granting_access?(resource_type, received_scope_list) }

      assert improperly_granted_resources.empty?,
             'User expected to deny the following resources that were granted: ' \
             "#{improperly_granted_resources.join(', ')}"
      assert improperly_denied_resources.empty?,
             'User expected to grant access to the following resources: ' \
             "#{improperly_denied_resources.join(', ')}"

      assert forbidden_resources.present?,
             'This test requires at least one resource to be denied, but the received scopes ' \
             "`#{received_scopes}` grant access to all resource types."

      pass "Resources to be denied: #{forbidden_resources.join(', ')}"
    end
  end
end
