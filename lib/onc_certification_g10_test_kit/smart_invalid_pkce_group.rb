module ONCCertificationG10TestKit
  class InvalidSMARTTokenRequestTest < Inferno::Test
    title 'OAuth token exchange fails when supplied invalid code_verifier'
    description %(
      If the request failed verification or is invalid, the authorization
      server returns an error response.
    )
    uses_request :redirect
    id :invalid_pkce_request

    input :code, :use_pkce, :pkce_code_verifier, :client_id, :client_secret, :smart_token_url

    def modify_oauth_params(oauth_params)
      oauth_params
    end

    run do
      skip_if request.query_parameters['error'].present?, 'Error during authorization request'

      oauth2_params = {
        grant_type: 'authorization_code',
        code: code,
        redirect_uri: config.options[:redirect_uri]
      }

      oauth2_headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }

      if client_secret.present?
        client_credentials = "#{client_id}:#{client_secret}"
        oauth2_headers['Authorization'] = "Basic #{Base64.strict_encode64(client_credentials)}"
      else
        oauth2_params[:client_id] = client_id
      end

      modify_oauth_params(oauth2_params)

      post(smart_token_url, body: oauth2_params, name: :token, headers: oauth2_headers)

      assert_response_status([400, 401])
    end
  end

  class SMARTInvalidPKCEGroup < Inferno::TestGroup
    title 'SMART App Launch Error: Invalid PKCE Code Verifier'
    short_title 'SMART Invalid PKCE Code Verifier'
    input_instructions %(
      Register Inferno as a standalone application using the following information:

      * Redirect URI: `#{SMARTAppLaunch::AppRedirectTest.config.options[:redirect_uri]}`
    )
    description %(
      # Background

      The #{title} Group verifies that a SMART Launch Sequence, specifically the
      [Standalone
      Launch](http://hl7.org/fhir/smart-app-launch/STU2/app-launch.html#launch-app-standalone-launch)
      Sequence, does not work in the case where the client sends an invalid PKCE
      `code_verifier`. This group performs four launches without a valid
      `code_verifier` and verifies that these do not result in a successful
      launch.

      This test is not included as part of a regular SMART Launch Sequence
      because some servers may not accept an authorization code after it has
      been used unsuccessfully in this manner.
    )
    id :g10_smart_invalid_pkce_code_verifier_group
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
        pkce_code_challenge: {
          name: :invalid_token_pkce_code_challenge
        },
        pkce_code_verifier: {
          name: :invalid_token_pkce_code_verifier
        }
      },
      outputs: {
        code: { name: :invalid_token_code },
        state: { name: :invalid_token_state },
        expires_in: { name: :invalid_token_expires_in },
        pkce_code_challenge: { name: :invalid_token_pkce_code_challenge },
        pkce_code_verifier: { name: :invalid_token_pkce_code_verifier }
      },
      requests: {
        redirect: { name: :invalid_token_redirect },
        token: { name: :invalid_token_token }
      }
    )

    test from: :smart_app_redirect_stu2,
         id: :smart_no_code_verifier_redirect,
         config: {
           options: {
             redirect_message_proc: lambda do |auth_url|
               %(
                ### Invalid PKCE code_verifier 1/4

                This launch does not provide a `code_verifier` and verifies the
                server does not issue an access token.

                [Follow this link to authorize with the SMART
                server](#{auth_url}).

                  Tests will resume once Inferno receives a request at
                  `#{config.options[:redirect_uri]}` with a state of `#{state}`.
               )
             end
           }
         }
    test from: :smart_code_received,
         id: :smart_no_code_verifier_code_received
    test from: :invalid_pkce_request do
      title 'OAuth token exchange fails when no code_verifier is given'
      id :smart_no_verifier_token_request
    end

    test from: :smart_app_redirect_stu2,
         id: :smart_blank_code_verifier_redirect,
         config: {
           options: {
             redirect_message_proc: lambda do |auth_url|
               %(
                ### Invalid PKCE code_verifier 2/4

                This launch provides a blank `code_verifier` and verifies the
                server does not issue an access token.

                [Follow this link to authorize with the SMART
                server](#{auth_url}).

                  Tests will resume once Inferno receives a request at
                  `#{config.options[:redirect_uri]}` with a state of `#{state}`.
               )
             end
           }
         }
    test from: :smart_code_received,
         id: :smart_blank_code_verifier_code_received
    test from: :invalid_pkce_request do
      title 'OAuth token exchange fails when code_verifier is blank'
      id :smart_blank_verifier_token_request

      def modify_oauth_params(oauth_params)
        oauth_params.merge!(code_verifier: '')
      end
    end

    test from: :smart_app_redirect_stu2,
         id: :smart_bad_code_verifier_redirect,
         config: {
           options: {
             redirect_message_proc: lambda do |auth_url|
               %(
                ### Invalid PKCE code_verifier 3/4

                This launch provides an invalid `code_verifier` and verifies the
                server does not issue an access token.

                [Follow this link to authorize with the SMART
                server](#{auth_url}).

                  Tests will resume once Inferno receives a request at
                  `#{config.options[:redirect_uri]}` with a state of `#{state}`.
               )
             end
           }
         }
    test from: :smart_code_received,
         id: :smart_bad_code_verifier_code_received
    test from: :invalid_pkce_request do
      title 'OAuth token exchange fails when code_verifier is incorrect'
      id :smart_bad_code_verifier_token_request

      def modify_oauth_params(oauth_params)
        oauth_params.merge!(code_verifier: "#{SecureRandom.uuid}-#{SecureRandom.uuid}")
      end
    end

    test from: :smart_app_redirect_stu2,
         id: :smart_plain_code_verifier_redirect,
         config: {
           options: {
             redirect_message_proc: lambda do |auth_url|
               %(
                ### Invalid PKCE code_verifier 4/4

                This launch provides a `plain` `code_verifier` instead of one
                encoded with `S256` and verifies the server does not issue an
                access token.

                [Follow this link to authorize with the SMART
                server](#{auth_url}).

                  Tests will resume once Inferno receives a request at
                  `#{config.options[:redirect_uri]}` with a state of `#{state}`.
               )
             end
           }
         }
    test from: :smart_code_received,
         id: :smart_plain_code_verifier_code_received
    test from: :invalid_pkce_request do
      title 'OAuth token exchange fails when code_verifier matches code_challenge'
      id :smart_plain_code_verifier_token_request

      input :pkce_code_challenge

      def modify_oauth_params(oauth_params)
        oauth_params.merge!(code_verifier: pkce_code_challenge)
      end
    end
  end
end
