require_relative 'authorization_request_builder'

module ONCCertificationG10TestKit
  class BulkDataAuthorization < Inferno::TestGroup
    title 'Bulk Data Authorization'
    short_description 'Demonstrate SMART Backend Services Authorization for Bulk Data.'

    id :bulk_data_authorization

    input :bulk_smart_auth_info,
          type: :auth_info,
          title: 'Multi-Patient API Credentials',
          options: {
            mode: :auth,
            components: [
              {
                name: :auth_type,
                default: 'backend_services',
                locked: true
              },
              {
                name: :use_discovery,
                default: false,
                locked: true
              },
              {
                name: :token_url,
                optional: false
              },
              {
                name: :jwks,
                locked: true
              }
            ]
          }

    output :bulk_smart_auth_info, :authentication_response

    test from: :tls_version_test do
      title 'Authorization service token endpoint secured by transport layer security'
      description <<~DESCRIPTION
        [§170.315(g)(10) Test
        Procedure](https://www.healthit.gov/test-method/standardized-api-patient-and-population-services)
        requires that all exchanges described herein between a client and a
        server SHALL be secured using Transport Layer Security (TLS) Protocol
        Version 1.2 (RFC5246).
      DESCRIPTION
      id :g10_bulk_token_tls_version

      input :bulk_smart_auth_info, type: :auth_info

      def url
        bulk_smart_auth_info.token_url
      end

      config(options: { minimum_allowed_version: OpenSSL::SSL::TLS1_2_VERSION })
    end

    test from: :smart_backend_services_invalid_grant_type do
      id :g10_bulk_invalid_grant_type
      config(inputs: { smart_auth_info: { name: :bulk_smart_auth_info } })
    end

    test from: :smart_backend_services_invalid_client_assertion do
      id :g10_bulk_invalid_client_assertion_type
      config(inputs: { smart_auth_info: { name: :bulk_smart_auth_info } })
    end

    test from: :smart_backend_services_invalid_jwt do
      id :g10_bulk_invalid_jwt
      config(inputs: { smart_auth_info: { name: :bulk_smart_auth_info } })
    end

    test from: :smart_backend_services_auth_request_success do
      id :g10_bulk_auth_request_success
      config(
        inputs: { smart_auth_info: { name: :bulk_smart_auth_info } },
        outputs: {
          smart_auth_info: { name: :bulk_smart_auth_info },
          authentication_response: { name: :authentication_response }
        }
      )
    end

    test from: :smart_backend_services_auth_response_body do
      id :g10_bulk_auth_response_body
      config(
        inputs: {
          smart_auth_info: { name: :bulk_smart_auth_info },
          authentication_response: { name: :authentication_response }
        }
      )
    end
  end
end
