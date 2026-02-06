RSpec.describe ONCCertificationG10TestKit::SMARTInvalidTokenRefreshTest do
  let(:test) { described_class }
  let(:suite_id) { 'g10_certification' }
  let(:default_inputs) do
    {
      smart_auth_info: Inferno::DSL::AuthInfo.new(
        token_url: 'http://example.com/token',
        client_id: 'CLIENT_ID',
        client_secret: 'CLIENT_SECRET',
        refresh_token: 'REFRESH_TOKEN',
        auth_type: 'symmetric'
      ),
      received_scopes: 'offline_access'
    }
  end

  it 'skips if the refresh token is blank' do
    default_inputs[:smart_auth_info].refresh_token = nil

    result = run(test, default_inputs)

    expect(result.result).to eq('skip')
    expect(result.result_message).to match(/refresh token/)
  end

  it 'fails if the token request succeeds' do
    stub_request(:post, default_inputs[:smart_auth_info].token_url)
      .to_return(status: 200)
    result = run(test, default_inputs)

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/200/)
  end

  it 'passes if the token request returns a 400' do
    stub_request(:post, default_inputs[:smart_auth_info].token_url)
      .to_return(status: 400)
    result = run(test, default_inputs)

    expect(result.result).to eq('pass')
  end

  context 'with asymmetric authentication' do
    let(:default_inputs) do
      {
        smart_auth_info: Inferno::DSL::AuthInfo.new(
          token_url: 'http://example.com/token',
          client_id: 'CLIENT_ID',
          client_secret: 'CLIENT_SECRET',
          refresh_token: 'REFRESH_TOKEN',
          auth_type: 'asymmetric',
          jwks: 'JWKS',
          encryption_algorithm: 'ES384'
        ),
        received_scopes: 'offline_access'
      }
    end

    it 'uses a client assertion' do
      stub_request(:post, default_inputs[:smart_auth_info].token_url)
        .with do |request|
          params = URI.decode_www_form(request.body).to_h
          params['client_assertion'] == 'CLIENT_ASSERTION' &&
            params['client_assertion_type'] == 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer'
        end
        .to_return(status: 400)

      allow(SMARTAppLaunch::ClientAssertionBuilder).to receive(:build).and_return('CLIENT_ASSERTION')

      result = run(test, default_inputs)

      expect(result.result).to eq('pass')
      expect(SMARTAppLaunch::ClientAssertionBuilder).to have_received(:build).with(
        iss: 'CLIENT_ID',
        sub: 'CLIENT_ID',
        aud: 'http://example.com/token',
        client_auth_encryption_method: 'ES384',
        custom_jwks: 'JWKS'
      )
    end
  end

  it 'passes if the token request returns a 401' do
    stub_request(:post, default_inputs[:smart_auth_info].token_url)
      .to_return(status: 401)
    result = run(test, default_inputs)

    expect(result.result).to eq('pass')
  end
end
