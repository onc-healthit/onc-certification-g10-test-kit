require_relative 'patient_context_test'
require_relative 'limited_scope_grant_test'

module G10CertificationTestKit
  class SmartLimitedAppGroup < Inferno::TestGroup
    title 'Standalone Patient App - Limited Access'
    description %(
      This scenario demonstrates the ability to perform a Patient Standalone
      Launch to a [SMART on FHIR](http://www.hl7.org/fhir/smart-app-launch/)
      confidential client with limited access granted to the app based on user
      input. The tester is expected to grant the application access to a subset
      of desired resource types.
    )
    id :g10_smart_limited_app
    run_as_group

    group from: :smart_standalone_launch do
      title 'Standalone Launch With Limited Scope'
      description %(
        # Background

        The [Standalone
        Launch](http://hl7.org/fhir/smart-app-launch/#standalone-launch-sequence)
        Sequence allows an app, like Inferno, to be launched independent of an
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
          Sequence](http://hl7.org/fhir/smart-app-launch/#standalone-launch-sequence)
      )

      input :expected_resources,
            title: 'Expected Resource Grant',
            description: 'The user will only grant access to the following resources during authorization.',
            default: 'Patient, Condition, Observation'

      test from: :g10_patient_context,
           config: {
             inputs: {
               patient_id: { name: :standalone_patient_id },
               access_token: { name: :standalone_access_token }
             }
           }

      test from: :g10_limited_scope_grant do
        config(
          inputs: {
            requested_scopes: { name: :standalone_requested_scopes },
            received_scopes: { name: :standalone_received_scopes }
          }
        )

        # def required_scopes
        #   ['openid', 'fhirUser', 'launch/patient', 'offline_access']
        # end

        # def scope_type
        #   'patient'
        # end
      end
    end
  end
end
