require_relative 'patient_context_test'
require_relative 'limited_scope_grant_test'
require_relative 'restricted_resource_type_access_group'

module ONCCertificationG10TestKit
  class SmartLimitedAppGroup < Inferno::TestGroup
    title 'Standalone Patient App - Limited Access'
    short_title 'Limited Access App'

    input_instructions %(
      The purpose of this test is to demonstrate that users can restrict access
      granted to apps to a limited number of resources. Enter which resources the
      user will grant access to below, and during the launch process only grant
      access to those resources. Inferno will verify that access granted matches
      these expectations.
    )

    description %(
      This scenario demonstrates the ability to perform a Patient Standalone
      Launch to a [SMART on FHIR](http://hl7.org/fhir/smart-app-launch/1.0.0/)
      confidential client with limited access granted to the app based on user
      input. The tester is expected to grant the application access to a subset
      of desired resource types.
    )
    id :g10_smart_limited_app
    run_as_group

    input_order :expected_resources,
                :limited_requested_scopes,
                :use_pkce,
                :pkce_code_challenge_method,
                :url,
                :standalone_client_id,
                :standalone_client_secret,
                :smart_authorization_url,
                :smart_token_url

    group from: :smart_standalone_launch do
      title 'Standalone Launch With Limited Scope'
      description %(
        # Background

        The [Standalone
        Launch Sequence](http://hl7.org/fhir/smart-app-launch/1.0.0/index.html#standalone-launch-sequence)
        allows an app, like Inferno, to be launched independent of an
        existing EHR session. It is one of the two launch methods described in
        the SMART App Launch Framework alongside EHR Launch. The app will
        request authorization for the provided scope from the authorization
        endpoint, ultimately receiving an authorization token which can be used
        to gain access to resources on the FHIR server.

        # Test Methodology

        Inferno will redirect the user to the the authorization endpoint so that
        they may provide any required credentials and authorize the application.
        Upon successful authorization, Inferno will exchange the authorization
        code provided for an access token.

        For more information on the #{title}:

        * [Standalone Launch
          Sequence](http://hl7.org/fhir/smart-app-launch/1.0.0/index.html#standalone-launch-sequence)
      )

      config(
        inputs: {
          client_id: { locked: true },
          client_secret: { locked: true },
          url: { locked: true },
          code: { name: :limited_code },
          state: { name: :limited_state },
          patient_id: { name: :limited_patient_id },
          access_token: { name: :limited_access_token },
          requested_scopes: {
            name: :limited_requested_scopes,
            title: 'Limited Access Scope'
          },
          # TODO: separate standalone/ehr discovery outputs
          smart_authorization_url: { locked: true, title: 'SMART Authorization Url' },
          smart_token_url: { locked: true, title: 'SMART Token Url' },
          received_scopes: { name: :limited_received_scopes },
          smart_credentials: { name: :limited_smart_credentials }
        },
        outputs: {
          code: { name: :limited_code },
          token_retrieval_time: { name: :limited_token_retrieval_time },
          state: { name: :limited_state },
          id_token: { name: :limited_id_token },
          refresh_token: { name: :limited_refresh_token },
          access_token: { name: :limited_access_token },
          expires_in: { name: :limited_expires_in },
          patient_id: { name: :limited_patient_id },
          encounter_id: { name: :limited_encounter_id },
          received_scopes: { name: :limited_received_scopes },
          intent: { name: :limited_intent },
          smart_credentials: { name: :limited_smart_credentials }
        },
        requests: {
          redirect: { name: :limited_redirect },
          token: { name: :limited_token }
        }
      )

      input :expected_resources,
            title: 'Expected Resource Grant',
            description: 'The user will only grant access to the following resources during authorization.',
            default: 'Patient, Condition, Observation'

      test from: :g10_patient_context,
           config: {
             inputs: {
               patient_id: { name: :limited_patient_id },
               smart_credentials: { name: :limited_smart_credentials }
             }
           }

      test from: :g10_limited_scope_grant do
        config(
          inputs: {
            requested_scopes: { name: :limited_requested_scopes },
            received_scopes: { name: :limited_received_scopes }
          }
        )
      end
    end

    group from: :g10_restricted_resource_type_access,
          config: {
            inputs: {
              patient_id: { name: :limited_patient_id },
              requested_scopes: { name: :limited_requested_scopes },
              received_scopes: { name: :limited_received_scopes },
              smart_credentials: { name: :limited_smart_credentials }
            }
          }
  end
end
