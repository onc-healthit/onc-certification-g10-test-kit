require_relative 'g10_options'
require_relative 'patient_context_test'
require_relative 'limited_scope_grant_test'
require_relative 'restricted_resource_type_access_group'

module ONCCertificationG10TestKit
  class SmartLimitedAppGroup < Inferno::TestGroup
    title 'Standalone Patient App - Limited Access'
    short_title 'Limited Access App'

    input_instructions %(
      The purpose of this test is to verify that patient app users can restrict
      access granted to apps to a limited number of resources Enter which
      resources the user will grant access to below, and during the launch
      process only grant access to those resources. Inferno will verify that
      access granted matches these expectations.

      All other inputs are locked to ensure the same app configuration as in the
      Standalone Patient App - Full Access test.
    )

    description %(
      This scenario verifies the ability of a system to perform a Patient Standalone
      Launch to a SMART on FHIR confidential client with limited access granted
      to the app based on user input. The tester is expected to grant the
      application access to a subset of desired resource types. The launch is
      performed using the same app configuration as in the Standalone Patient
      App test, demonstrating that the user has control over what scopes are
      granted to the app as required in the (g)(10) Standardized API criterion.

      The following implementation specifications are relevant to this scenario:

      * [SMART on FHIR
        (STU1)](http://www.hl7.org/fhir/smart-app-launch/1.0.0/)
      * [SMART on FHIR
        (STU2)](http://hl7.org/fhir/smart-app-launch/STU2)
    )
    id :g10_smart_limited_app
    run_as_group

    input_order :expected_resources,
                :use_pkce,
                :pkce_code_challenge_method,
                :url,
                :standalone_client_id,
                :standalone_client_secret,
                :smart_authorization_url,
                :smart_token_url,
                :standalone_requested_scopes,
                :authorization_method,
                :client_auth_type,
                :client_auth_encryption_method

    group from: :smart_standalone_launch do
      title 'Standalone Launch With Limited Scope'
      description %(
        # Background

        The [Standalone
        Launch Sequence](http://hl7.org/fhir/smart-app-launch/1.0.0/index.html#standalone-launch-sequence)
        allows an app, like Inferno, to be launched independent of an
        existing EHR session. It is one of the two launch methods described in
        the SMART App Launch Framework alongside EHR Launch. The app will
        request authorization for the provided scope(s) from the authorization
        endpoint, and the user of the app will choose to either grant
        the app access to the requested scope(s), or to deny one or all of the requested
        scope(s).

        This test verifies the ability of a server to provide a user
        with the choice of which scopes to grant an app.  Allowing users to choose
        which resource types to grant access to is a requirement of the ONC
        (g)(10) certification criteria.  Prior to the test, the tester specifies
        which resource types will be granted, and then during the authorization
        process the tester grants access to those scopes.

        # Test Methodology

        Inferno will redirect the user to the authorization endpoint so that
        they may provide any required credentials and authorize the application.
        Upon successful authorization, Inferno will exchange the authorization
        code provided for an access token. Inferno verifies that the server only
        grants access to the resources specified by the user.

        For more information on the #{title}:

        * [Standalone Launch
          Sequence](http://hl7.org/fhir/smart-app-launch/1.0.0/index.html#standalone-launch-sequence)
      )

      required_suite_options G10Options::SMART_1_REQUIREMENT

      config(
        inputs: {
          client_id: { locked: true },
          client_secret: { locked: true, optional: false },
          url: { locked: true },
          requested_scopes: { locked: true },
          code: { name: :limited_code },
          state: { name: :limited_state },
          patient_id: { name: :limited_patient_id },
          access_token: { name: :limited_access_token },
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
        },
        options: {
          ignore_missing_scopes_check: true,
          redirect_message_proc: lambda do |auth_url|
            expected_resource_string =
              expected_resources
                .split(',')
                .map(&:strip)
                .map { |resource_type| "* #{resource_type}\n" }
                .join

            <<~MESSAGE
              ### #{self.class.parent.parent.title}

              [Follow this link to authorize with the SMART
              server](#{auth_url}).

              Tests will resume once Inferno receives a request at
              `#{REDIRECT_URI}` with a state of `#{state}`.

              Access should only be granted to the following resources:

              #{expected_resource_string}
            MESSAGE
          end
        }
      )

      input :expected_resources,
            title: 'Expected Resource Grant for Limited Access Launch',
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
            received_scopes: { name: :limited_received_scopes }
          }
        )
      end
    end

    group from: :smart_standalone_launch_stu2,
          config: {
            inputs: {
              use_pkce: {
                default: 'true',
                locked: true
              },
              pkce_code_challenge_method: {
                locked: true
              }
            }
          } do
      title 'Standalone Launch With Limited Scope'
      description %(
        # Background

        The [Standalone
        Launch Sequence](http://hl7.org/fhir/smart-app-launch/STU2/app-launch.html#launch-app-standalone-launch)
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
          Sequence](http://hl7.org/fhir/smart-app-launch/STU2/app-launch.html#launch-app-standalone-launch)
      )

      required_suite_options(G10Options::SMART_2_REQUIREMENT)

      config(
        inputs: {
          client_id: { locked: true },
          client_secret: { locked: true },
          url: { locked: true },
          requested_scopes: { locked: true },
          code: { name: :limited_code },
          state: { name: :limited_state },
          patient_id: { name: :limited_patient_id },
          access_token: { name: :limited_access_token },
          # TODO: separate standalone/ehr discovery outputs
          smart_authorization_url: { locked: true, title: 'SMART Authorization Url' },
          smart_token_url: { locked: true, title: 'SMART Token Url' },
          received_scopes: { name: :limited_received_scopes },
          smart_credentials: { name: :limited_smart_credentials },
          client_auth_type: {
            locked: true,
            default: 'confidential_symmetric'
          }
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
        },
        options: {
          ignore_missing_scopes_check: true,
          redirect_message_proc: lambda do |auth_url|
            expected_resource_string =
              expected_resources
                .split(',')
                .map(&:strip)
                .map { |resource_type| "* #{resource_type}\n" }
                .join

            <<~MESSAGE
              ### #{self.class.parent.parent.title}

              [Follow this link to authorize with the SMART
              server](#{auth_url}).

              Tests will resume once Inferno receives a request at
              `#{REDIRECT_URI}` with a state of `#{state}`.

              Access should only be granted to the following resources:

              #{expected_resource_string}
            MESSAGE
          end
        }
      )

      input :expected_resources,
            title: 'Expected Resource Grant for Limited Access Launch',
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
            received_scopes: { name: :limited_received_scopes }
          }
        )
      end
    end

    group from: :smart_standalone_launch_stu2_2, # rubocop:disable Naming/VariableNumber
          config: {
            inputs: {
              use_pkce: {
                default: 'true',
                locked: true
              },
              pkce_code_challenge_method: {
                locked: true
              }
            }
          } do
      title 'Standalone Launch With Limited Scope'
      description %(
        # Background

        The [Standalone
        Launch Sequence](http://hl7.org/fhir/smart-app-launch/STU2.2/app-launch.html#launch-app-standalone-launch)
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
          Sequence](http://hl7.org/fhir/smart-app-launch/STU2.2/app-launch.html#launch-app-standalone-launch)
      )

      required_suite_options(G10Options::SMART_2_2_REQUIREMENT)

      config(
        inputs: {
          client_id: { locked: true },
          client_secret: { locked: true },
          url: { locked: true },
          requested_scopes: { locked: true },
          code: { name: :limited_code },
          state: { name: :limited_state },
          patient_id: { name: :limited_patient_id },
          access_token: { name: :limited_access_token },
          # TODO: separate standalone/ehr discovery outputs
          smart_authorization_url: { locked: true, title: 'SMART Authorization Url' },
          smart_token_url: { locked: true, title: 'SMART Token Url' },
          received_scopes: { name: :limited_received_scopes },
          smart_credentials: { name: :limited_smart_credentials },
          client_auth_type: {
            locked: true,
            default: 'confidential_symmetric'
          }
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
        },
        options: {
          ignore_missing_scopes_check: true,
          redirect_message_proc: lambda do |auth_url|
            expected_resource_string =
              expected_resources
                .split(',')
                .map(&:strip)
                .map { |resource_type| "* #{resource_type}\n" }
                .join

            <<~MESSAGE
              ### #{self.class.parent.parent.title}

              [Follow this link to authorize with the SMART
              server](#{auth_url}).

              Tests will resume once Inferno receives a request at
              `#{REDIRECT_URI}` with a state of `#{state}`.

              Access should only be granted to the following resources:

              #{expected_resource_string}
            MESSAGE
          end
        }
      )

      input :expected_resources,
            title: 'Expected Resource Grant for Limited Access Launch',
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
            received_scopes: { name: :limited_received_scopes }
          }
        )
      end
    end

    group from: :g10_restricted_resource_type_access,
          config: {
            inputs: {
              patient_id: { name: :limited_patient_id },
              received_scopes: { name: :limited_received_scopes },
              smart_credentials: { name: :limited_smart_credentials }
            }
          }
  end
end
