module G10CertificationTestKit
  class G10SmartStandalonePatientApp < Inferno::TestGroup
    title 'Standalone Patient App'
    description %(
        This scenario demonstrates the ability of a system to perform a Patient
        Standalone Launch to a [SMART on
        FHIR](http://www.hl7.org/fhir/smart-app-launch/) confidential client
        with a patient context, refresh token, and [OpenID Connect
        (OIDC)](https://openid.net/specs/openid-connect-core-1_0.html) identity
        token. After launch, a simple Patient resource read is performed on the
        patient in context. The access token is then refreshed, and the Patient
        resource is read using the new access token to ensure that the refresh
        was successful. The authentication information provided by OpenID
        Connect is decoded and validated, and simple queries are performed to
        ensure that access is granted to all USCDI data elements.
      )
    id :g10_smart_standalone_patient_app
    run_as_group

    group from: :smart_discovery do
      test do
        title 'Well-known configuration declares support for required capabilities'
        description %(
          A SMART on FHIR server SHALL convey its capabilities to app developers
          by listing the SMART core capabilities supported by their
          implementation within the Well-known configuration file. This test
          ensures that the capabilities required by this scenario are properly
          documented in the Well-known file.
        )
        input :well_known_configuration

        run do
          skip_if well_known_configuration.blank?, 'No well-known SMART configuration found.'

          assert_valid_json(well_known_configuration)
          capabilities = JSON.parse(well_known_configuration)['capabilities']
          assert capabilities.is_a?(Array),
                 "Expected the well-known capabilities to be an Array, but found #{capabilities.class.name}"

          required_smart_capabilities = [
            'launch-standalone',
            'client-public',
            'client-confidential-symmetric',
            'sso-openid-connect',
            'context-standalone-patient',
            'permission-offline',
            'permission-patient'
          ]

          missing_capabilities = required_smart_capabilities - capabilities
          assert missing_capabilities.empty?,
                 "The following capabilities required for this scenario are missing: #{missing_capabilities.join(', ')}"
        end
      end
    end

    group from: :smart_standalone_launch do
      title 'Standalone Launch With Patient Scope'
      test do
        title 'Patient-level access with OpenID Connect and Refresh Token scopes used.'
        description %(
          The scopes being input must follow the guidelines specified in the
          smart-app-launch guide. All scopes requested are expected to be
          granted.
        )
        input :requested_scopes, name: :standalone_requested_scopes
        input :received_scopes, name: :standalone_received_scopes
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

        def required_scopes
          ['openid', 'fhirUser', 'launch/patient', 'offline_access']
        end

        def requested_scope_test(scopes, patient_compartment_resource_types, patient_or_user)
          patient_scope_found = false

          scopes.each do |scope|
            bad_format_message =
              "Requested scope '#{scope}' does not follow the format: `#{patient_or_user}" \
              '/[ resource | * ].[ read | * ]`'

            scope_pieces = scope.split('/')
            assert scope_pieces.count == 2, bad_format_message

            resource_access = scope_pieces[1].split('.')
            bad_resource_message = "'#{resource_access[0]}' must be either a valid resource type or '*'"

            if patient_or_user == 'patient' && patient_compartment_resource_types.exclude?(resource_access[0])
              assert ['user', 'patient'].include?(scope_pieces[0]),
                     "Requested scope '#{scope}' must begin with either 'user/' or 'patient/'"
            else
              assert scope_pieces[0] == patient_or_user, bad_format_message
            end

            assert resource_access.count == 2, bad_format_message
            assert valid_resource_types.include?(resource_access[0]), bad_resource_message
            assert resource_access[1] =~ /^(\*|read)/, bad_format_message

            patient_scope_found = true
          end

          assert patient_scope_found,
                 "#{patient_or_user.capitalize}-level scope in the format: " \
                 "`#{patient_or_user}/[ resource | * ].[ read | *]` was not requested."
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
              requested_scope_test(scopes, patient_compartment_resource_types, 'patient')
            else
              received_scope_test(scopes, patient_compartment_resource_types)
            end
          end
        end
      end

      test do
        title 'Server rejects unauthorized access'
        description %(
          A server SHALL reject any unauthorized requests by returning an HTTP
          401 unauthorized response code.
        )
        input :patient_id, name: :standalone_patient_id
        input :url
        uses_request :token

        fhir_client :standalone_unauthenticated do
          url :url
        end

        run do
          skip_if request.status != 200, 'Token exchange was unsuccessful'
          skip_if patient_id.blank?, 'Patient context expected to verify unauthorized read.'

          fhir_read(:patient, patient_id, client: :standalone_unauthenticated)

          assert_response_status(401)
        end
      end

      test do
        title 'OAuth token exchange response body contains patient context and patient resource can be retrieved'
        description %(
          The `patient` field is a String value with a patient id, indicating
          that the app was launched in the context of this FHIR Patient.
        )
        input :patient_id, name: :standalone_patient_id
        input :access_token, name: :standalone_access_token
        input :url

        fhir_client :standalone_authenticated do
          url :url
          bearer_token :access_token
        end

        run do
          skip_if access_token.blank?, 'No access token was received during the SMART launch'

          skip_if patient_id.blank?, 'Token response did not contain `patient` field'

          fhir_read(:patient, patient_id, client: :standalone_authenticated)

          assert_response_status(200)
          assert_resource_type(:patient)
        end
      end
    end

    group from: :smart_openid_connect,
          config: {
            inputs: {
              id_token: { name: :standalone_id_token },
              client_id: { name: :standalone_client_id },
              requested_scopes: { name: :standalone_requested_scopes },
              access_token: { name: :standalone_access_token }
            }
          }

    group do
      id :smart_standalone_refresh_without_scopes
      title 'Token Refresh'
      description %(
        # Background

        The #{title} Sequence tests the ability of the system to successfuly
        exchange a refresh token for an access token. Refresh tokens are typically
        longer lived than access tokens and allow client applications to obtain a
        new access token Refresh tokens themselves cannot provide access to
        resources on the server.

        Token refreshes are accomplished through a `POST` request to the token
        exchange endpoint as described in the [SMART App Launch
        Framework](http://www.hl7.org/fhir/smart-app-launch/#step-5-later-app-uses-a-refresh-token-to-obtain-a-new-access-token).

        # Test Methodology

        This test attempts to exchange the refresh token for a new access token
        and verify that the information returned contains the required fields and
        uses the proper headers.

        For more information see:

        * [The OAuth 2.0 Authorization
          Framework](https://tools.ietf.org/html/rfc6749)
        * [Using a refresh token to obtain a new access
          token](http://hl7.org/fhir/smart-app-launch/#step-5-later-app-uses-a-refresh-token-to-obtain-a-new-access-token)
      )

      config(
        inputs: {
          refresh_token: { name: :standalone_refresh_token },
          client_id: { name: :standalone_client_id },
          client_secret: { name: :standalone_client_secret },
          received_scopes: { name: :standalone_received_scopes }
        },
        outputs: {
          refresh_token: { name: :standalone_refresh_token },
          received_scopes: { name: :standalone_received_scopes },
          access_token: { name: :standalone_access_token },
          token_retrieval_time: { name: :standalone_token_retrieval_time },
          expires_in: { name: :standalone_expires_in }
        }
      )

      test from: :smart_token_refresh,
           id: :token_refresh_without_scopes,
           config: {
             options: { include_scopes: false }
           }
      test from: :smart_token_refresh_body,
           id: :token_refresh_body_without_scopes
      test from: :smart_token_refresh,
           title: 'Server successfully refreshes the access token when optional scope parameter provided',
           id: :token_refresh_with_scopes,
           config: {
             options: { include_scopes: true }
           }
      test from: :smart_token_refresh_body,
           id: :token_refresh_body_with_scopes

      # TODO: remove duplication
      test do
        title 'OAuth token exchange response body contains patient context and patient resource can be retrieved'
        description %(
          The `patient` field is a String value with a patient id, indicating
          that the app was launched in the context of this FHIR Patient.
        )
        input :patient_id, name: :standalone_patient_id
        input :access_token, name: :standalone_access_token
        input :url
        uses_request :token_refresh

        fhir_client :standalone_authenticated do
          url :url
          bearer_token :access_token
        end

        run do
          skip_if access_token.blank?, 'No access token was received during the SMART launch'

          skip_if patient_id.blank?, 'Token response did not contain `patient` field'

          skip_if request.status != 200, 'Token was not successfully refreshed'

          fhir_read(:patient, patient_id, client: :standalone_authenticated)

          assert_response_status(200)
          assert_resource_type(:patient)
        end
      end
    end
  end
end
