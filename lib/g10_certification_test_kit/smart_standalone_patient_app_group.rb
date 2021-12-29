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

    group from: :smart_standalone_launch

    group from: :smart_openid_connect,
          config: {
            inputs: {
              id_token: { name: :standalone_id_token },
              client_id: { name: :standalone_client_id },
              requested_scopes: { name: :standalone_requested_scopes }
            }
          }

    group from: :smart_token_refresh,
          id: :smart_standalone_refresh_without_scopes,
          title: 'SMART Token Refresh Without Scopes',
          config: {
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
          }

    group from: :smart_token_refresh,
          id: :smart_standalone_refresh_with_scopes,
          title: 'SMART Token Refresh With Scopes',
          config: {
            options: { include_scopes: true },
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
          }
  end
end
