module ONCCertificationG10TestKit
  class SMARTScopesTest < Inferno::Test
    include G10Options

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
      (VALID_RESOURCE_TYPES + ['ServiceRequest', 'QuestionnaireResponse', 'Media']).freeze

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
      return PATIENT_COMPARTMENT_RESOURCE_TYPES unless using_us_core_5?

      V5_PATIENT_COMPARTMENT_RESOURCE_TYPES
    end

    def valid_resource_types
      return VALID_RESOURCE_TYPES unless using_us_core_5?

      V5_VALID_RESOURCE_TYPES
    end

    def required_scope_type
      config.options[:required_scope_type]
    end

    def required_scopes
      config.options[:required_scopes]
    end

    def read_format
      @read_format ||=
        begin
          v1_read_format = 'read'
          v2_read_format = 'c?ru?d?s?'

          case config.options[:scope_version]
          when :v1
            "#{v1_read_format} | *"
          when :v2
            "#{v2_read_format} | *"
          else
            [v1_read_format, v2_read_format, '*'].join(' | ')
          end
        end
    end

    def access_level_regex
      @access_level_regex ||=
        case config.options[:scope_version]
        when :v1
          /\A(\*|read)/
        when :v2
          /\A(\*|c?ru?d?s?\b)/
        else
          /\A(\*|read|c?ru?d?s?\b)/
        end
    end

    def bad_format_message(scope)
      %(
        Requested scope `#{scope}` does not follow the format:
        `#{required_scope_type}/[ <ResourceType> | * ].[ #{read_format} ]`
      )
    end

    def strip_experimental_scope_syntax(full_scope)
      if config.options[:scope_version] == :v1
        full_scope
      else
        full_scope.split('?').first
      end
    end

    def requested_scope_test(scopes, patient_compartment_resource_types)
      correct_scope_type_found = false

      scopes.each do |full_scope|
        scope = strip_experimental_scope_syntax(full_scope)

        scope_pieces = scope.split('/')
        assert scope_pieces.count == 2, bad_format_message(scope)

        scope_type, resource_scope = scope_pieces
        resource_scope_parts = resource_scope.split('.')

        assert resource_scope_parts.length == 2, bad_format_message(scope)

        resource_type, access_level = resource_scope_parts
        bad_resource_message = "'#{resource_type}' must be either a valid resource type or '*'"

        if required_scope_type == 'patient' && patient_compartment_resource_types.exclude?(resource_type)
          assert ['user', 'patient'].include?(scope_type),
                 "Requested scope '#{scope}' must begin with either 'user/' or 'patient/'"
        else
          assert scope_type == required_scope_type, bad_format_message(scope)
        end

        assert valid_resource_types.include?(resource_type), bad_resource_message
        assert access_level =~ access_level_regex, bad_format_message(scope)

        correct_scope_type_found = true
      end

      assert correct_scope_type_found,
             "#{required_scope_type.capitalize}-level scope in the format: " \
             "`#{required_scope_type}/[ <ResourceType> | * ].[ #{read_format} ]` was not requested."
    end

    def received_scope_test(scopes, patient_compartment_resource_types)
      granted_resource_types = []

      scopes.each do |full_scope|
        scope = strip_experimental_scope_syntax(full_scope)

        scope_pieces = scope.split('/')
        next unless scope_pieces.count == 2

        _scope_type, resource_scope = scope_pieces

        resource_scope_parts = resource_scope.split('.')
        next unless resource_scope_parts.count == 2

        resource_type, access_level = resource_scope_parts
        granted_resource_types << resource_type if access_level =~ access_level_regex
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
