require_relative 'base_token_refresh_group'
require_relative 'smart_scopes_test'
require_relative 'unauthorized_access_test'
require_relative 'well_known_capabilities_test'

module G10CertificationTestKit
  class SmartEHRPractitionerAppGroup < Inferno::TestGroup
    title 'EHR Practitioner App'
    description %(
      Demonstrate the ability to perform an EHR launch to a [SMART on
      FHIR](http://www.hl7.org/fhir/smart-app-launch/) confidential client with
      patient context, refresh token, and [OpenID Connect
      (OIDC)](https://openid.net/specs/openid-connect-core-1_0.html) identity
      token. After launch, a simple Patient resource read is performed on the
      patient in context. The access token is then refreshed, and the Patient
      resource is read using the new access token to ensure that the refresh was
      successful. Finally, the authentication information provided by OpenID
      Connect is decoded and validated.
    )
    id :g10_smart_ehr_practitioner_app
    run_as_group

    config(
      inputs: {
        client_id: {
          default: 'SAMPLE_CONFIDENTIAL_CLIENT_ID'
        },
        client_secret: {
          optional: false,
          default: 'SAMPLE_CONFIDENTIAL_CLIENT_SECRET'
        },
        smart_credentials: {
          name: :ehr_smart_credentials
        }
      }
    )

    group from: :smart_discovery do
      test from: 'g10_smart_well_known_capabilities'
    end

    group from: :smart_ehr_launch do
      title 'EHR Launch With Practitioner Scope'

      config(
        inputs: {
          requested_scopes: {
            default: %(
              launch openid fhirUser offline_access user/Medication.read
              user/AllergyIntolerance.read user/CarePlan.read user/CareTeam.read
              user/Condition.read user/Device.read user/DiagnosticReport.read
              user/DocumentReference.read user/Encounter.read user/Goal.read
              user/Immunization.read user/Location.read
              user/MedicationRequest.read user/Observation.read
              user/Organization.read user/Patient.read user/Practitioner.read
              user/Procedure.read user/Provenance.read
              user/PractitionerRole.read
            ).gsub(/\s{2,}/, ' ').strip
          }
        }
      )

      test from: :g10_smart_scopes do
        title 'User-level access with OpenID Connect and Refresh Token scopes used.'
        config(
          inputs: {
            requested_scopes: { name: :ehr_requested_scopes },
            received_scopes: { name: :ehr_received_scopes }
          }
        )

        def required_scopes
          ['openid', 'fhirUser', 'launch', 'offline_access']
        end

        def scope_type
          'user'
        end
      end

      test from: :g10_unauthorized_access,
           config: {
             inputs: {
               patient_id: { name: :ehr_patient_id }
             }
           }

      test from: :g10_patient_context,
           config: {
             inputs: {
               patient_id: { name: :ehr_patient_id },
               access_token: { name: :ehr_access_token }
             }
           }

      test do
        title 'Launch context contains smart_style_url which links to valid JSON'
        description %(
          In order to mimic the style of the SMART host more closely, SMART apps
          can check for the existence of this launch context parameter and
          download the JSON file referenced by the URL value.
        )
        uses_request :token

        run do
          skip_if request.status != 200, 'No token response received'
          assert_valid_json response[:body]

          body = JSON.parse(response[:body])

          assert body['smart_style_url'].present?,
                 'Token response did not contain `smart_style_url`'

          get(body['smart_style_url'])

          assert_response_status(200)
          assert_valid_json(response[:body])
        end
      end

      test do
        title 'Launch context contains need_patient_banner'
        description %(
          `need_patient_banner` is a boolean value indicating whether the app
          was launched in a UX context where a patient banner is required (when
          true) or not required (when false).
        )
        uses_request :token

        run do
          skip_if request.status != 200, 'No token response received'
          assert_valid_json response[:body]

          body = JSON.parse(response[:body])

          assert body.key?('need_patient_banner'),
                 'Token response did not contain `need_patient_banner`'
        end
      end
    end

    group from: :smart_openid_connect,
          config: {
            inputs: {
              id_token: { name: :ehr_id_token },
              client_id: { name: :ehr_client_id },
              requested_scopes: { name: :ehr_requested_scopes },
              smart_credentials: { name: :ehr_smart_credentials }
            }
          }

    group from: :g10_token_refresh do
      id :g10_smart_ehr_token_refresh

      config(
        inputs: {
          refresh_token: { name: :ehr_refresh_token },
          client_id: { name: :ehr_client_id },
          client_secret: { name: :ehr_client_secret },
          received_scopes: { name: :ehr_received_scopes }
        },
        outputs: {
          refresh_token: { name: :ehr_refresh_token },
          received_scopes: { name: :ehr_received_scopes },
          access_token: { name: :ehr_access_token },
          token_retrieval_time: { name: :ehr_token_retrieval_time },
          expires_in: { name: :ehr_expires_in },
          smart_credentials: { name: :ehr_smart_credentials }
        }
      )

      test from: :g10_patient_context do
        config(
          inputs: {
            patient_id: { name: :ehr_patient_id }
          },
          options: {
            refresh_test: true
          }
        )
        uses_request :token_refresh
      end
    end

    test do
      id :g10_ehr_credentials_export
      title 'Set SMART Credentials to EHR Launch Credentials'

      input :ehr_smart_credentials, type: :oauth_credentials
      output :smart_credentials

      run do
        output smart_credentials: ehr_smart_credentials.to_s
      end
    end
  end
end
