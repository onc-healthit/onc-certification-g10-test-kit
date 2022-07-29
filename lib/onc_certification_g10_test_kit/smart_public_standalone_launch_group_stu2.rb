module ONCCertificationG10TestKit
  class SMARTPublicStandaloneLaunchGroupSTU2 < SMARTAppLaunch::StandaloneLaunchGroupSTU2
    title 'Public Client Standalone Launch with OpenID Connect'
    short_title 'SMART Public Client Launch'
    input_instructions %(
      Register Inferno as a standalone application using the following information:

      * Redirect URI: `#{SMARTAppLaunch::AppRedirectTest.config.options[:redirect_uri]}`

      Enter in the appropriate scope to enable patient-level access to all
      relevant resources. In addition, support for the OpenID Connect (openid
      fhirUser), refresh tokens (offline_access), and patient context
      (launch/patient) are required.
    )
    id :g10_public_standalone_launch_stu2
    run_as_group

    config(
      inputs: {
        client_id: {
          name: :public_client_id,
          title: 'Public Launch Client ID'
        },
        client_secret: {
          name: :public_client_secret,
          title: 'Public Launch Client Secret',
          default: nil,
          optional: true,
          locked: true
        },
        requested_scopes: {
          name: :public_requested_scopes,
          title: 'Public Launch Scope'
        },
        url: {
          title: 'Public Launch FHIR Endpoint',
          description: 'URL of the FHIR endpoint used by standalone applications'
        },
        code: {
          name: :public_code
        },
        state: {
          name: :public_state
        },
        smart_authorization_url: {
          title: 'OAuth 2.0 Authorize Endpoint',
          description: 'OAuth 2.0 Authorize Endpoint provided during the patient standalone launch'
        },
        smart_token_url: {
          title: 'OAuth 2.0 Token Endpoint',
          description: 'OAuth 2.0 Token Endpoint provided during the patient standalone launch'
        },
        smart_credentials: {
          name: :public_smart_credentials
        },
        use_pkce: {
          default: 'true',
          locked: true
        },
        pkce_code_challenge_method: {
          locked: true
        }
      },
      outputs: {
        code: { name: :public_code },
        token_retrieval_time: { name: :public_token_retrieval_time },
        state: { name: :public_state },
        id_token: { name: :public_id_token },
        refresh_token: { name: :public_refresh_token },
        access_token: { name: :public_access_token },
        expires_in: { name: :public_expires_in },
        patient_id: { name: :public_patient_id },
        encounter_id: { name: :public_encounter_id },
        received_scopes: { name: :public_received_scopes },
        intent: { name: :public_intent },
        smart_credentials: { name: :public_smart_credentials }
      },
      requests: {
        redirect: { name: :public_redirect },
        token: { name: :public_token }
      }
    )

    input_order :url,
                :public_client_id,
                :public_client_secret,
                :public_requested_scopes,
                :use_pkce,
                :pkce_code_challenge_method,
                :smart_authorization_url,
                :smart_token_url

    test from: :g10_patient_context,
         config: {
           inputs: {
             patient_id: { name: :public_patient_id },
             smart_credentials: { name: :public_smart_credentials }
           }
         }

    test do
      title 'OAuth token exchange response contains OpenID Connect id_token'
      description %(
        This test requires that an OpenID Connect id_token is provided to
        demonstrate authentication capabilies for public clients.
      )
      id :g10_public_launch_id_token

      input :id_token,
            name: :public_id_token,
            locked: true,
            optional: true

      run do
        assert id_token.present?, 'Token response did not provide an id_token as required.'
      end
    end
  end
end
