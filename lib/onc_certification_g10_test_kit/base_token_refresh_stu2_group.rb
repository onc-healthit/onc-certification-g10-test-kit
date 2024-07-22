require_relative 'smart_invalid_token_refresh_test'

module ONCCertificationG10TestKit
  class BaseTokenRefreshSTU2Group < Inferno::TestGroup
    title 'Token Refresh'
    description %(
      # Background

      The #{title} Sequence tests the ability of the system to successfuly
      exchange a refresh token for an access token. Refresh tokens are typically
      longer lived than access tokens and allow client applications to obtain a
      new access token Refresh tokens themselves cannot provide access to
      resources on the server.

      Token refreshes are accomplished through a `POST` request to the token
      exchange endpoint as described in the SMART App Launch Framework.

      # Test Methodology

      This test attempts to exchange the refresh token for a new access token
      and verify that the information returned contains the required fields and
      uses the proper headers.

      For more information see:

      * [The OAuth 2.0 Authorization
        Framework](https://tools.ietf.org/html/rfc6749)
      * [Using a refresh token to obtain a new access token
        (STU2)](http://hl7.org/fhir/smart-app-launch/STU2/app-launch.html#refresh-access-token)
    )
    id :g10_token_refresh_stu2

    test from: :smart_token_refresh_stu2,
         id: :g10_token_refresh_without_scopes,
         config: {
           options: { include_scopes: false }
         }
    test from: :smart_token_refresh_body,
         id: :g10_token_refresh_body_without_scopes
    test from: :smart_token_refresh,
         title: 'Server successfully refreshes the access token when optional scope parameter provided',
         id: :g10_token_refresh_with_scopes,
         config: {
           options: { include_scopes: true }
         }
    test from: :smart_token_refresh_body,
         id: :g10_token_refresh_body_with_scopes
  end
end
