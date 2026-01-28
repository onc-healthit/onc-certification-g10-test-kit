require_relative '../../lib/onc_certification_g10_test_kit/bulk_data_authorization'

RSpec.describe ONCCertificationG10TestKit::BulkDataAuthorization do
  let(:group) { Inferno::Repositories::TestGroups.new.find('bulk_data_authorization') }
  let(:suite_id) { 'g10_certification' }
  let(:bulk_token_endpoint) { 'http://example.com/fhir' }
  let(:bulk_encryption_method) { 'ES384' }
  let(:bulk_scope) { 'system/Patient.read' }
  let(:bulk_client_id) { 'clientID' }
  let(:bulk_smart_auth_info) do
    Inferno::DSL::AuthInfo.new(
      token_url: bulk_token_endpoint,
      encryption_algorithm: bulk_encryption_method,
      requested_scopes: bulk_scope,
      client_id: bulk_client_id,
      jwks: ONCCertificationG10TestKit::BulkDataJWKSHelper.jwks_json
    )
  end
  let(:input) { { bulk_smart_auth_info: } }

  describe '[Invalid grant_type] test' do
    let(:runnable) { group.tests[1] }

    it 'fails when token endpoint allows invalid grant_type' do
      stub_request(:post, bulk_token_endpoint)
        .with(body: hash_including(grant_type: 'not_a_grant_type'))
        .to_return(status: 200)

      result = run(runnable, input)
      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Unexpected response status: expected 400, but received 200')
    end

    it 'passes when token endpoint requires valid grant_type' do
      stub_request(:post, bulk_token_endpoint)
        .with(body: hash_including(grant_type: 'not_a_grant_type'))
        .to_return(status: 400)

      result = run(runnable, input)

      expect(result.result).to eq('pass')
    end
  end

  describe '[Invalid client_assertion_type] test' do
    let(:runnable) { group.tests[2] }

    it 'fails when token endpoint allows invalid client_assertion_type' do
      stub_request(:post, bulk_token_endpoint)
        .with(body: hash_including(client_assertion_type: 'not_an_assertion_type'))
        .to_return(status: 200)

      result = run(runnable, input)
      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/Unexpected response status:/)
    end

    it 'passes when token endpoint requires valid client_assertion_type (400)' do
      stub_request(:post, bulk_token_endpoint)
        .with(body: hash_including(client_assertion_type: 'not_an_assertion_type'))
        .to_return(status: 400)

      result = run(runnable, input)

      expect(result.result).to eq('pass')
    end

    it 'passes when token endpoint requires valid client_assertion_type (401)' do
      stub_request(:post, bulk_token_endpoint)
        .with(body: hash_including(client_assertion_type: 'not_an_assertion_type'))
        .to_return(status: 401)

      result = run(runnable, input)

      expect(result.result).to eq('pass')
    end
  end

  describe '[Invalid JWT token] test' do
    let(:runnable) { group.tests[3] }

    it 'fails when token endpoint allows invalid JWT token' do
      stub_request(:post, bulk_token_endpoint)
        .to_return(status: 200)

      result = run(runnable, input)
      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Unexpected response status: expected 400, 401, but received 200')
    end

    it 'passes when token endpoint requires valid JWT token' do
      stub_request(:post, bulk_token_endpoint)
        .to_return(status: 400)

      result = run(runnable, input)

      expect(result.result).to eq('pass')
    end
  end

  describe '[Authorization request succeeds when supplied correct information] test' do
    let(:runnable) { group.tests[4] }

    it 'fails if the access token request is rejected' do
      stub_request(:post, bulk_token_endpoint)
        .to_return(status: 400)

      result = run(runnable, input)
      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Unexpected response status: expected 200, 201, but received 400')
    end

    it 'passes if the access token request is valid and authorized' do
      stub_request(:post, bulk_token_endpoint)
        .to_return(status: 200)

      result = run(runnable, input)

      expect(result.result).to eq('pass')
    end
  end

  describe '[Authorization request response body contains required information encoded in JSON] test' do
    let(:runnable) { group.tests[5] }
    let(:response_body) do
      {
        'access_token' => 'this_is_the_token',
        'token_type' => 'bearer',
        'expires_in' => 300,
        'scope' => 'system'
      }
    end

    it 'skips when no authentication request found' do
      result = run(runnable, input)

      expect(result.result).to eq('skip')
      expect(result.result_message).to match(/Input/i).and match(/nil/i)
    end

    it 'fails when authentication response is invalid JSON' do
      repo_create(
        :request,
        test_session_id: test_session.id,
        name: :bulk_authentication,
        response_body: '{/}'
      )

      result = run(runnable, input.merge(bulk_authentication: '{/}'))
      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Invalid JSON. ')
    end

    it 'fails when authentication response does not contain access_token' do
      repo_create(
        :request,
        test_session_id: test_session.id,
        name: :bulk_authentication,
        response_body: '{"response_body":"post"}'
      )

      result = run(runnable, input.merge(bulk_authentication: '{"response_body":"post"}'))
      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Token response did not contain access_token as required')
    end

    it 'fails when access_token is present but does not contain required keys' do
      repo_create(
        :request,
        test_session_id: test_session.id,
        name: :bulk_authentication,
        response_body: { 'access_token' => 'its_the_token' }.to_json
      )

      result = run(runnable, input.merge(bulk_authentication: { 'access_token' => 'its_the_token' }.to_json))
      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Token response did not contain token_type as required')
    end

    it 'passes when access_token is present and contains the required keys' do
      repo_create(
        :request,
        test_session_id: test_session.id,
        name: :bulk_authentication,
        response_body: response_body.to_json
      )

      result = run(runnable, input.merge(bulk_authentication: response_body.to_json))

      expect(result.result).to eq('pass')
    end
  end
end
