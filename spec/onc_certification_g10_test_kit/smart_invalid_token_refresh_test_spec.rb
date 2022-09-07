RSpec.describe ONCCertificationG10TestKit::SMARTInvalidTokenRefreshTest do
  def run(runnable, inputs = {})
    test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
    test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
    inputs.each do |name, value|
      session_data_repo.save(
        test_session_id: test_session.id,
        name: name,
        value: value,
        type: runnable.config.input_type(name)
      )
    end
    Inferno::TestRunner.new(test_session: test_session, test_run: test_run).run(runnable)
  end

  let(:test) { described_class }
  let(:test_session) { repo_create(:test_session, test_suite_id: 'g10_certification') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
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
    expect(result.result_message).to match(/No refresh token/)
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
