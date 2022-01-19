require_relative 'base_token_refresh_group'
require_relative 'patient_context_test'
require_relative 'smart_scopes_test'
require_relative 'unauthorized_access_test'
require_relative 'unrestricted_resource_type_access_group'
require_relative 'well_known_capabilities_test'

module G10CertificationTestKit
  class SmartStandalonePatientAppGroup < Inferno::TestGroup
    title 'Standalone Patient App - Full Access'
    description %(
        This scenario demonstrates the ability of a system to perform a Patient
        Standalone Launch to a [SMART on
        FHIR](http://www.hl7.org/fhir/smart-app-launch/) confidential client
        with a patient context, refresh token, 1 1 and [OpenID Connect
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
      test from: 'g10_smart_well_known_capabilities'
    end

    group from: :smart_standalone_launch do
      title 'Standalone Launch With Patient Scope'
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

      test from: :g10_smart_scopes do
        config(
          inputs: {
            requested_scopes: { name: :standalone_requested_scopes },
            received_scopes: { name: :standalone_received_scopes }
          }
        )

        def required_scopes
          ['openid', 'fhirUser', 'launch/patient', 'offline_access']
        end

        def scope_type
          'patient'
        end
      end

      test from: :g10_unauthorized_access,
           config: {
             inputs: {
               patient_id: { name: :standalone_patient_id }
             }
           }

      test from: :g10_patient_context,
           config: {
             inputs: {
               patient_id: { name: :standalone_patient_id },
               access_token: { name: :standalone_access_token }
             }
           }
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

    group from: :g10_token_refresh do
      id :g10_smart_standalone_token_refresh

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

      test from: :g10_patient_context do
        config(
          inputs: {
            patient_id: { name: :standalone_patient_id },
            access_token: { name: :standalone_access_token }
          },
          options: {
            refresh_test: true
          }
        )
        uses_request :token_refresh
      end
    end

    group from: :g10_unrestricted_resource_type_access,
          config: {
            inputs: {
              access_token: { name: :standalone_access_token },
              received_scopes: { name: :standalone_received_scopes },
              patient_id: { name: :standalone_patient_id },
            }
          }
  end
end
