module ONCCertificationG10TestKit
  class SMARTInvalidTokenGroupSTU2 < Inferno::TestGroup
    title 'Invalid Access Token Request'
    short_title 'Invalid Token Request'
    input_instructions %(
      Register Inferno as a standalone application using the following information:

      * Redirect URI: `#{REDIRECT_URI}`
    )
    description %(
      This scenario verifies that a SMART Launch
      Sequence, specifically the [Standalone
      Launch](http://hl7.org/fhir/smart-app-launch/STU2/app-launch.html#launch-app-standalone-launch)
      Sequence, does not succeed in the case where the client sends an invalid
      Authorization code or client ID during the code exchange step. This must
      not result in a successful launch.

      This test is not included as part of earlier scenarios because some
      servers may not accept an authorization code after it has been used
      unsuccessfully in this manner.
    )
    id :g10_smart_invalid_token_request_stu2
    run_as_group

    input :use_pkce,
          title: 'Proof Key for Code Exchange (PKCE)',
          type: 'radio',
          default: 'true',
          locked: true,
          options: {
            list_options: [
              {
                label: 'Enabled',
                value: 'true'
              },
              {
                label: 'Disabled',
                value: 'false'
              }
            ]
          }
    input :pkce_code_challenge_method,
          optional: true,
          title: 'PKCE Code Challenge Method',
          type: 'radio',
          default: 'S256',
          locked: true,
          options: {
            list_options: [
              {
                label: 'S256',
                value: 'S256'
              },
              {
                label: 'Plain',
                value: 'plain'
              }
            ]
          }

    input_order :url,
                :standalone_client_id,
                :standalone_client_secret,
                :standalone_requested_scopes,
                :use_pkce,
                :pkce_code_challenge_method,
                :smart_authorization_url,
                :smart_token_url

    config(
      inputs: {
        client_id: {
          name: :standalone_client_id,
          title: 'Standalone Client ID',
          description: 'Client ID provided during registration of Inferno as a standalone application'
        },
        client_secret: {
          name: :standalone_client_secret,
          title: 'Standalone Client Secret',
          description: 'Client Secret provided during registration of Inferno as a standalone application'
        },
        requested_scopes: {
          name: :standalone_requested_scopes,
          title: 'Standalone Scope',
          description: 'OAuth 2.0 scope provided by system to enable all required functionality',
          type: 'textarea',
          default: %(
            launch/patient openid fhirUser offline_access
            patient/Medication.read patient/AllergyIntolerance.read
            patient/CarePlan.read patient/CareTeam.read patient/Condition.read
            patient/Device.read patient/DiagnosticReport.read
            patient/DocumentReference.read patient/Encounter.read
            patient/Goal.read patient/Immunization.read patient/Location.read
            patient/MedicationRequest.read patient/Observation.read
            patient/Organization.read patient/Patient.read
            patient/Practitioner.read patient/Procedure.read
            patient/Provenance.read patient/PractitionerRole.read
          ).gsub(/\s{2,}/, ' ').strip
        },
        url: {
          title: 'Standalone FHIR Endpoint',
          description: 'URL of the FHIR endpoint used by standalone applications'
        },
        code: {
          name: :invalid_token_code
        },
        state: {
          name: :invalid_token_state
        },
        smart_authorization_url: {
          title: 'OAuth 2.0 Authorize Endpoint',
          description: 'OAuth 2.0 Authorize Endpoint provided during the patient standalone launch'
        },
        smart_token_url: {
          title: 'OAuth 2.0 Token Endpoint',
          description: 'OAuth 2.0 Token Endpoint provided during the patient standalone launch'
        },
        pkce_code_verifier: {
          name: :invalid_token_pkce_code_verifier
        },
        client_auth_type: {
          locked: true,
          default: 'confidential_symmetric'
        }
      },
      outputs: {
        code: { name: :invalid_token_code },
        state: { name: :invalid_token_state },
        expires_in: { name: :invalid_token_expires_in },
        pkce_code_verifier: { name: :invalid_token_pkce_code_verifier }
      },
      requests: {
        redirect: { name: :invalid_token_redirect },
        token: { name: :invalid_token_token }
      }
    )

    test from: :smart_app_redirect_stu2
    test from: :smart_code_received

    test do
      title ' OAuth token exchange fails when supplied invalid code'
      description %(
        If the request failed verification or is invalid, the authorization
        server returns an error response.
      )
      uses_request :redirect

      input :use_pkce, :client_id, :client_secret, :smart_token_url
      input :pkce_code_verifier,
            optional: true
      run do
        skip_if request.query_parameters['error'].present?, 'Error during authorization request'

        oauth2_params = {
          grant_type: 'authorization_code',
          code: 'BAD_CODE',
          redirect_uri: REDIRECT_URI
        }
        oauth2_headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }

        if client_secret.present?
          client_credentials = "#{client_id}:#{client_secret}"
          oauth2_headers['Authorization'] = "Basic #{Base64.strict_encode64(client_credentials)}"
        else
          oauth2_params[:client_id] = client_id
        end

        oauth2_params[:code_verifier] = pkce_code_verifier if use_pkce == 'true'

        post(smart_token_url, body: oauth2_params, name: :token, headers: oauth2_headers)

        assert_response_status(400)
      end
    end

    test do
      title 'OAuth token exchange fails when supplied invalid client ID'
      description %(
        If the request failed verification or is invalid, the authorization
        server returns an error response.
      )
      uses_request :redirect

      input :use_pkce, :code, :smart_token_url, :client_secret
      input :pkce_code_verifier,
            optional: true

      run do
        skip_if request.query_parameters['error'].present?, 'Error during authorization request'

        client_id = 'BAD_CLIENT_ID'

        oauth2_params = {
          grant_type: 'authorization_code',
          code:,
          redirect_uri: REDIRECT_URI
        }
        oauth2_headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }

        if client_secret.present?
          client_credentials = "#{client_id}:#{client_secret}"
          oauth2_headers['Authorization'] = "Basic #{Base64.strict_encode64(client_credentials)}"
        else
          oauth2_params[:client_id] = client_id
        end

        oauth2_params[:code_verifier] = pkce_code_verifier if use_pkce == 'true'

        post(smart_token_url, body: oauth2_params, name: :token, headers: oauth2_headers)

        assert_response_status([400, 401])
      end
    end
  end
end
