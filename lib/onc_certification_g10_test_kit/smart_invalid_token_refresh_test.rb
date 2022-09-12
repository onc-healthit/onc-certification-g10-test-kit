module ONCCertificationG10TestKit
  class SMARTInvalidTokenRefreshTest < Inferno::Test
    id :g10_invalid_token_refresh
    title 'Refresh token exchange fails when supplied an invalid refresh token'
    description %(
      If the request failed verification or is invalid, the authorization server
      returns an error response.

      [OAuth 2.0 RFC (6749)](https://www.rfc-editor.org/rfc/rfc6749#section-6)
    )
    input :refresh_token, :smart_token_url, :client_id, :received_scopes
    input :client_secret, optional: true

    run do
      skip_if refresh_token.blank?, 'No refresh token was received'

      oauth2_params = {
        'grant_type' => 'refresh_token',
        'refresh_token' => SecureRandom.uuid
      }
      oauth2_headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }

      oauth2_params['scope'] = received_scopes if config.options[:include_scopes]

      if client_secret.present?
        credentials = Base64.strict_encode64("#{client_id}:#{client_secret}")
        oauth2_headers['Authorization'] = "Basic #{credentials}"
      else
        oauth2_params['client_id'] = client_id
      end

      post(smart_token_url, body: oauth2_params, headers: oauth2_headers)

      assert_response_status([400, 401])
    end
  end
end
