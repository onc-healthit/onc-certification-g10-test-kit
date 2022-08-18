module ONCCertificationG10TestKit
  class SMARTScopesTest < Inferno::Test
    title 'Patient-level access with OpenID Connect and Refresh Token scopes used.'
    description %(
      The scopes being input must follow the guidelines specified in the
      smart-app-launch guide. All scopes requested are expected to be granted.
    )
    id :g10_smart_scopes
    input :requested_scopes, :received_scopes
    uses_request :token

    VALID_RESOURCE_TYPES = [
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
    ].freeze

    V5_VALID_RESOURCE_TYPES =
      (VALID_RESOURCE_TYPES + ['ServiceRequest', 'QuestionnaireResponse']).freeze

    PATIENT_COMPARTMENT_RESOURCE_TYPES = [
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

    V5_PATIENT_COMPARTMENT_RESOURCE_TYPES =
      (PATIENT_COMPARTMENT_RESOURCE_TYPES + ['ServiceRequest']).freeze

    def patient_compartment_resource_types
      return PATIENT_COMPARTMENT_RESOURCE_TYPES unless suite_options[:us_core_version] == 'us_core_5'

      V5_PATIENT_COMPARTMENT_RESOURCE_TYPES
    end

    def valid_resource_types
      return VALID_RESOURCE_TYPES unless suite_options[:us_core_version] == 'us_core_5'

      V5_VALID_RESOURCE_TYPES
    end

    def requested_scope_test(scopes, patient_compartment_resource_types)
      correct_scope_type_found = false

      scopes.each do |scope|
        bad_format_message =
          "Requested scope '#{scope}' does not follow the format: `#{required_scope_type}" \
          '/[ resource | * ].[ read | * ]`'

        scope_pieces = scope.split('/')
        assert scope_pieces.count == 2, bad_format_message
        scope_type, resource_scope = scope_pieces

        resource_scope_parts = resource_scope.split('.')

        resource_type, access_level = resource_scope_parts
        bad_resource_message = "'#{resource_type}' must be either a valid resource type or '*'"

        if required_scope_type == 'patient' && patient_compartment_resource_types.exclude?(resource_type)
          assert ['user', 'patient'].include?(scope_type),
                 "Requested scope '#{scope}' must begin with either 'user/' or 'patient/'"
        else
          assert scope_type == required_scope_type, bad_format_message
        end

        assert resource_scope_parts.length == 2, bad_format_message
        assert valid_resource_types.include?(resource_type), bad_resource_message
        assert access_level =~ /^(\*|read)/, bad_format_message

        correct_scope_type_found = true
      end

      assert correct_scope_type_found,
             "#{required_scope_type.capitalize}-level scope in the format: " \
             "`#{required_scope_type}/[ resource | * ].[ read | *]` was not requested."
    end

    def received_scope_test(scopes, patient_compartment_resource_types)
      granted_resource_types = []

      scopes.each do |scope|
        scope_pieces = scope.split('/')
        next unless scope_pieces.count == 2

        _scope_type, resource_scope = scope_pieces

        resource_scope_parts = resource_scope.split('.')
        next unless resource_access.count == 2

        resource_type, access_level = resource_scope_parts
        granted_resource_types << resource_type if access_level =~ /^(\*|read)/
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
