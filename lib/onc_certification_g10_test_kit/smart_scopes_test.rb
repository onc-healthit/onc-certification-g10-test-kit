module G10CertificationTestKit
  class SMARTScopesTest < Inferno::Test
    title 'Patient-level access with OpenID Connect and Refresh Token scopes used.'
    description %(
      The scopes being input must follow the guidelines specified in the
      smart-app-launch guide. All scopes requested are expected to be granted.
    )
    id :g10_smart_scopes
    input :requested_scopes, :received_scopes
    uses_request :token

    def valid_resource_types
      [
        '*',
        'Patient',
        'AllergyIntolerance',
        'Binary',
        'CarePlan',
        'CareTeam',
        'Condition',
        'Device',
        'DiagnosticReport',
        'DocumentReference',
        'Encounter',
        'Goal',
        'Immunization',
        'Location',
        'Medication',
        'MedicationOrder',
        'MedicationRequest',
        'MedicationStatement',
        'Observation',
        'Organization',
        'Person',
        'Practitioner',
        'PractitionerRole',
        'Procedure',
        'Provenance',
        'RelatedPerson'
      ]
    end

    def requested_scope_test(scopes, patient_compartment_resource_types)
      patient_scope_found = false

      scopes.each do |scope|
        bad_format_message =
          "Requested scope '#{scope}' does not follow the format: `#{scope_type}" \
          '/[ resource | * ].[ read | * ]`'

        scope_pieces = scope.split('/')
        assert scope_pieces.count == 2, bad_format_message

        resource_access = scope_pieces[1].split('.')
        bad_resource_message = "'#{resource_access[0]}' must be either a valid resource type or '*'"

        if scope_type == 'patient' && patient_compartment_resource_types.exclude?(resource_access[0])
          assert ['user', 'patient'].include?(scope_pieces[0]),
                 "Requested scope '#{scope}' must begin with either 'user/' or 'patient/'"
        else
          assert scope_pieces[0] == scope_type, bad_format_message
        end

        assert resource_access.count == 2, bad_format_message
        assert valid_resource_types.include?(resource_access[0]), bad_resource_message
        assert resource_access[1] =~ /^(\*|read)/, bad_format_message

        patient_scope_found = true
      end

      assert patient_scope_found,
             "#{scope_type.capitalize}-level scope in the format: " \
             "`#{scope_type}/[ resource | * ].[ read | *]` was not requested."
    end

    def received_scope_test(scopes, patient_compartment_resource_types)
      granted_resource_types = []

      scopes.each do |scope|
        scope_pieces = scope.split('/')
        next unless scope_pieces.count == 2

        resource_access = scope_pieces[1].split('.')
        next unless resource_access.count == 2

        granted_resource_types << resource_access[0] if resource_access[1] =~ /^(\*|read)/
      end

      missing_resource_types =
        if granted_resource_types.include?('*')
          []
        else
          patient_compartment_resource_types - granted_resource_types - ['*']
        end

      assert missing_resource_types.empty?,
             "Request scopes #{missing_resource_types.join(', ')} were not granted by authorization server."
    end

    run do
      skip_if request.status != 200, 'Token exchange was unsuccessful'

      patient_compartment_resource_types = [
        '*',
        'Patient',
        'AllergyIntolerance',
        'CarePlan',
        'CareTeam',
        'Condition',
        'DiagnosticReport',
        'DocumentReference',
        'Goal',
        'Immunization',
        'MedicationRequest',
        'Observation',
        'Procedure',
        'Provenance'
      ].freeze

      [
        {
          scopes: requested_scopes,
          received_or_requested: 'requested'
        },
        {
          scopes: received_scopes,
          received_or_requested: 'received'
        }
      ].each do |metadata|
        scopes = metadata[:scopes].split
        received_or_requested = metadata[:received_or_requested]

        missing_scopes = required_scopes - scopes
        assert missing_scopes.empty?,
               "Required scopes were not #{received_or_requested}: #{missing_scopes.join(', ')}"

        scopes -= required_scopes

        # Other 'okay' scopes. Also scopes may include both 'launch' and
        # 'launch/patient' for EHR launch and Standalone launch.
        # 'launch/encounter' is mentioned by SMART App Launch though not in
        # (g)(10) test procedure
        scopes -= ['online_access', 'launch', 'launch/patient', 'launch/encounter']

        if received_or_requested == 'requested'
          requested_scope_test(scopes, patient_compartment_resource_types)
        else
          received_scope_test(scopes, patient_compartment_resource_types)
        end
      end
    end
  end
end
