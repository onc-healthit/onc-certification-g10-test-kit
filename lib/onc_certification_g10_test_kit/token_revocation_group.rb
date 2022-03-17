module ONCCertificationG10TestKit
  class TokenRevocationGroup < Inferno::TestGroup
    title 'Token Revocation'
    description 'Demonstrate the Health IT module is capable of revoking access granted to an application.'
    id :g10_token_revocation
    run_as_group

    input_order :token_revocation_attestation,
                :token_revocation_notes,
                :standalone_access_token,
                :standalone_refresh_token,
                :standalone_patient_id,
                :url,
                :smart_token_url,
                :standalone_client_id,
                :standalone_client_secret

    test do
      title 'Health IT developer demonstrated the ability of the Health IT Module to revoke tokens.'
      description %(
        Health IT developer demonstrated the ability of the Health IT Module /
        authorization server to revoke tokens.
      )

      input :token_revocation_attestation,
            title: 'Prior to executing test, Health IT developer demonstrated revoking tokens provided during patient standalone launch.', # rubocop:disable Layout/LineLength
            type: 'radio',
            default: 'false',
            options: {
              list_options: [
                {
                  label: 'Yes',
                  value: 'true'
                },
                {
                  label: 'No',
                  value: 'false'
                }
              ]
            }
      input :token_revocation_notes,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert token_revocation_attestation == 'true',
               'Health IT Module did not demonstrate support for application registration for single patients.'
        pass token_revocation_notes if token_revocation_notes.present?
      end
    end

    test do
      title 'Access to Patient resource returns unauthorized after token revocation.'
      description %(
        This test checks that the Patient resource returns unuathorized after token revocation.
      )

      input :url,
            title: 'FHIR Endpoint',
            description: 'URL of the FHIR endpoint used by standalone applications'
      input :patient_id,
            name: :standalone_patient_id,
            title: 'Patient ID',
            description: 'Patient ID associated with revoked tokens provided as context in the patient standalone launch. This will be used to verify access is no longer granted using the revoked token.' # rubocop:disable Layout/LineLength
      input :access_token,
            name: :standalone_access_token,
            title: 'Revoked Bearer Token',
            description: 'Prior to the test, please revoke this bearer token from patient standalone launch.'

      fhir_client :revoked_token do
        url :url
        bearer_token :access_token
      end

      run do
        skip_if patient_id.blank?,
                'Patient ID not provided to test. The patient ID is typically provided ' \
                'during a SMART launch context.'
        skip_if access_token.blank?,
                'Bearer token not provided. This test verifies that the bearer token can ' \
                'no longer be used to access a Patient resource.'

        fhir_read(:patient, patient_id, client: :revoked_token)

        assert_response_status([401, 403, 404])
      end
    end

    test do
      title 'Token refresh fails after token revocation.'
      description %(
        This test checks that refreshing token fails after token revokation.
      )

      input :smart_token_url,
            title: 'OAuth 2.0 Token Endpoint',
            description: 'OAuth token endpoint provided during the patient standalone launch'
      input :refresh_token,
            name: :standalone_refresh_token,
            title: 'Revoked Refresh Token',
            description: 'Prior to the test, please revoke this refresh token from patient standalone launch.'
      input :client_id,
            name: :standalone_client_id,
            title: 'Standalone Client ID',
            description: 'Client ID provided during registration of Inferno as a standalone application',
            locked: true
      input :client_secret,
            name: :standalone_client_secret,
            title: 'Standalone Client Secret',
            description: 'Client Secret provided during registration of Inferno as a standalone application',
            locked: true

      run do
        skip_if refresh_token.blank?,
                'Refresh token not provided to test.'
        oauth2_params = {
          'grant_type' => 'refresh_token',
          'refresh_token' => refresh_token
        }
        client_credentials = "#{client_id}:#{client_secret}"
        oauth2_headers = {
          'Content-Type' => 'application/x-www-form-urlencoded',
          'Authorization' => "Basic #{Base64.strict_encode64(client_credentials)}"
        }

        post(smart_token_url, body: oauth2_params, headers: oauth2_headers)

        assert_response_status([400, 401])
      end
    end
  end
end
