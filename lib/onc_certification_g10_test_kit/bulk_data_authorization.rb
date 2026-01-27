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
                default: "#{Inferno::Application['base_url']}/custom/g10_certification/jwks",
                locked: true
              }
            ]
          }

    output :bulk_smart_auth_info

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
      description <<~DESCRIPTION
        The Backend Service Authorization specification defines the required fields for the
        authorization request, made via HTTP POST to authorization token endpoint.
        This includes the `grant_type` parameter, where the value must be `client_credentials`.

        The OAuth 2.0 Authorization Framework describes the proper response for an
        invalid request in the client credentials grant flow:

        ```
        If the request failed client authentication or is invalid, the authorization server returns an
        error response as described in [Section 5.2](https://tools.ietf.org/html/rfc6749#section-5.2).
        ```
      DESCRIPTION
      config(inputs: { smart_auth_info: { name: :bulk_smart_auth_info } })
    end

    test from: :smart_backend_services_invalid_client_assertion do
      id :g10_bulk_invalid_client_assertion_type
      description <<~DESCRIPTION
        The Backend Service Authorization specification defines the required fields for the
        authorization request, made via HTTP POST to authorization token endpoint.
        This includes the `client_assertion_type` parameter, where the value must be `urn:ietf:params:oauth:client-assertion-type:jwt-bearer`.

        The OAuth 2.0 Authorization Framework describes the proper response for an
        invalid request in the client credentials grant flow:

        ```
        If the request failed client authentication or is invalid, the authorization server returns an
        error response as described in [Section 5.2](https://tools.ietf.org/html/rfc6749#section-5.2).
        ```
      DESCRIPTION
      config(inputs: { smart_auth_info: { name: :bulk_smart_auth_info } })
    end

    test from: :smart_backend_services_invalid_jwt do
      id :g10_bulk_invalid_jwt
      description <<~DESCRIPTION
        The Backend Service Authorization specification defines the required fields for the
        authorization request, made via HTTP POST to authorization token endpoint.
        This includes the `client_assertion` parameter, where the value must be
        a valid JWT. The JWT SHALL include the following claims, and SHALL be signed with the client’s private key.

        | JWT Claim | Required? | Description |
        | --- | --- | --- |
        | iss | required | Issuer of the JWT -- the client's client_id, as determined during registration with the FHIR authorization server (note that this is the same as the value for the sub claim) |
        | sub | required | The service's client_id, as determined during registration with the FHIR authorization server (note that this is the same as the value for the iss claim) |
        | aud | required | The FHIR authorization server's "token URL" (the same URL to which this authentication JWT will be posted) |
        | exp | required | Expiration time integer for this authentication JWT, expressed in seconds since the "Epoch" (1970-01-01T00:00:00Z UTC). This time SHALL be no more than five minutes in the future. |
        | jti | required | A nonce string value that uniquely identifies this authentication JWT. |

        The OAuth 2.0 Authorization Framework describes the proper response for an
        invalid request in the client credentials grant flow:

        ```
        If the request failed client authentication or is invalid, the authorization server returns an
        error response as described in [Section 5.2](https://tools.ietf.org/html/rfc6749#section-5.2).
        ```
      DESCRIPTION
      config(inputs: { smart_auth_info: { name: :bulk_smart_auth_info } })
    end

    test from: :smart_backend_services_auth_request_success do
      id :g10_bulk_auth_request_success
      description <<~DESCRIPTION
        If the access token request is valid and authorized, the authorization server SHALL issue an access token in response.
      DESCRIPTION
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
      description <<~DESCRIPTION
        The access token response SHALL be a JSON object with the following properties:

        | Token Property | Required? | Description |
        | --- | --- | --- |
        | access_token | required | The access token issued by the authorization server. |
        | token_type | required | Fixed value: bearer. |
        | expires_in | required | The lifetime in seconds of the access token. The recommended value is 300, for a five-minute token lifetime. |
        | scope | required | Scope of access authorized. Note that this can be different from the scopes requested by the app. |
      DESCRIPTION
      config(
        inputs: {
          smart_auth_info: { name: :bulk_smart_auth_info },
          authentication_response: { name: :authentication_response }
        }
      )
    end
  end
end
