RSpec.describe ONCCertificationG10TestKit::SMARTInvalidTokenRefreshTest do
  let(:test) { described_class }
  let(:suite_id) { 'g10_certification' }
  let(:default_inputs) do
    {
      smart_token_url: 'http://example.com/token',
      client_id: 'CLIENT_ID',
      client_secret: 'CLIENT_SECRET',
      received_scopes: 'offline_access',
      refresh_token: 'REFRESH_TOKEN'
    }
  end

  it 'skips if the refresh token is blank' do
    default_inputs.delete(:refresh_token)

    result = run(test, default_inputs)

    expect(result.result).to eq('skip')
    expect(result.result_message).to match(/refresh_token/)
  end

  it 'fails if the token request succeeds' do
    stub_request(:post, default_inputs[:smart_token_url])
      .to_return(status: 200)
    result = run(test, default_inputs)

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/200/)
  end

  it 'passes if the token request returns a 400' do
    stub_request(:post, default_inputs[:smart_token_url])
      .to_return(status: 400)
    result = run(test, default_inputs)

    expect(result.result).to eq('pass')
  end

  it 'passes if the token request returns a 401' do
    stub_request(:post, default_inputs[:smart_token_url])
      .to_return(status: 401)
    result = run(test, default_inputs)

    expect(result.result).to eq('pass')
  end
end
