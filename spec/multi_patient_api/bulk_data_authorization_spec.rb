#require_relative '../../../dev_suites/dev_multi_patient_api/bulk_data_access/bulk_data_authorization'

require_relative '../../../lib/multi_patient_api/bulk_data_authorization.rb'
require_relative '../../../lib/multi_patient_api/bulk_data_utils.rb'

#require_relative '../../../dev_suites/dev_multi_patient_api/bulk_data_access/bulk_data_utils'

RSpec.describe MultiPatientAPI::BulkDataAuthorization do
  include BulkDataUtils

  let(:suite) { Inferno::Repositories::TestSuites.new.find('multi_patient_api') }
  let(:group) { Inferno::Repositories::TestGroups.new.find('bulk_data_authorization') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: 'multi_patient_api') }
  let(:bulk_token_endpoint) { 'http://example.com/fhir' }
  let(:bulk_encryption_method) { 'ES384' }
  let(:bulk_scope) { 'system/Patient.read' }
  let(:bulk_client_id) { 'clientID' }
  let(:exp) { 5.minutes.from_now }
  let(:jti) { SecureRandom.hex(32) }
  let(:default_input) do
    {
      bulk_token_endpoint: bulk_token_endpoint,
      bulk_encryption_method: bulk_encryption_method,
      bulk_scope: bulk_scope,
      bulk_client_id: bulk_client_id
    }
  end
  let(:client_assertion_input) do
    {
      encryption_method: bulk_encryption_method,
      iss: bulk_client_id,
      sub: bulk_client_id,
      aud: bulk_token_endpoint,
      exp: exp,
      jti: jti
    }
  end

  def run(runnable, inputs = {})
    test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
    test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
    inputs.each do |name, value|
      session_data_repo.save(test_session_id: test_session.id, name: name, value: value)
    end
    Inferno::TestRunner.new(test_session: test_session, test_run: test_run).run(runnable)
  end

  # TODO: After TLS tester class is implemented, create this test
  describe 'endpoint TLS tests' do
  end

  describe '[Invalid grant_type] test' do
    let(:runnable) { group.tests[1] }
    let(:client_assertion) { create_client_assertion(client_assertion_input) }
    let(:body) do
      {
        'scope' => bulk_scope,
        'grant_type' => 'not_a_grant_type',
        'client_assertion_type' => 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
        'client_assertion' => client_assertion.to_s
      }.compact
    end

    it 'passes when token endpoint requires valid grant_type' do
      stub_request(:post, bulk_token_endpoint)
        .with(body: body)
        .to_return(status: 400, body: "", headers: {})

      allow_any_instance_of(described_class).to receive(:create_client_assertion).and_return(client_assertion)
      result = run(runnable, default_input)

      expect(result.result).to eq('pass')
    end

    it 'fails when token endpoint allows invalid grant_type' do
      stub_request(:post, bulk_token_endpoint)
        .with(body: body)
        .to_return(status: 200, body: "", headers: {})

      allow_any_instance_of(described_class).to receive(:create_client_assertion).and_return(client_assertion)
      result = run(runnable, default_input)
      
      expect(result.result).to eq('fail')
    end
  end

  describe '[Invalid client_assertion_type] test' do
    let(:runnable) { group.tests[2] }
    let(:client_assertion) { create_client_assertion(client_assertion_input) }
    let(:body) do
      {
        'scope' => bulk_scope,
        'grant_type' => 'client_credentials',
        'client_assertion_type' => 'not_an_assertion_type',
        'client_assertion' => client_assertion.to_s
      }.compact
    end

    it 'passes when token endpoint requires valid client_assertion_type' do
      stub_request(:post, bulk_token_endpoint)
        .with(body: body)
        .to_return(status: 400, body: "", headers: {})

      allow_any_instance_of(described_class).to receive(:create_client_assertion).and_return(client_assertion)
      result = run(runnable, default_input)

      expect(result.result).to eq('pass')
    end

    it 'fails when token endpoint allows invalid client_assertion_type' do
      stub_request(:post, bulk_token_endpoint)
        .with(body: body)
        .to_return(status: 200, body: "", headers: {})

      allow_any_instance_of(described_class).to receive(:create_client_assertion).and_return(client_assertion)
      result = run(runnable, default_input)
      
      expect(result.result).to eq('fail')
    end
  end

  describe '[Invalid JWT token] test' do
    let(:runnable) { group.tests[3] }
    let(:client_assertion) do
      client_assertion_input[:iss] = 'not_a_valid_iss'
      create_client_assertion(client_assertion_input) 
    end
    let(:body) do
      {
        'scope' => bulk_scope,
        'grant_type' => 'client_credentials',
        'client_assertion_type' => 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
        'client_assertion' => client_assertion.to_s
      }.compact
    end

    it 'passes when token endpoint requires valid JWT token' do
      stub_request(:post, bulk_token_endpoint)
        .with(body: body)
        .to_return(status: 400, body: "", headers: {})

      allow_any_instance_of(described_class).to receive(:create_client_assertion).and_return(client_assertion)
      result = run(runnable, default_input)

      expect(result.result).to eq('pass')
    end

    it 'fails when token endpoint allows invalid JWT token' do
      stub_request(:post, bulk_token_endpoint)
        .with(body: body)
        .to_return(status: 200, body: "", headers: {})

      allow_any_instance_of(described_class).to receive(:create_client_assertion).and_return(client_assertion)
      result = run(runnable, default_input)
      
      expect(result.result).to eq('fail')
    end
  end

  describe 'Authorization request succeeds when supplied correct information test' do
    let(:runnable) { group.tests[4] }
    let(:client_assertion) { create_client_assertion(client_assertion_input) }
    let(:body) do
      {
        'scope' => bulk_scope,
        'grant_type' => 'client_credentials',
        'client_assertion_type' => 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
        'client_assertion' => client_assertion.to_s
      }.compact
    end

    it 'passes if the access token request is valid and authorized' do
      stub_request(:post, bulk_token_endpoint)
        .with(body: body)
        .to_return(status: 200, body: '', headers: {})

      allow_any_instance_of(described_class).to receive(:create_client_assertion).and_return(client_assertion)
      result = run(runnable, default_input)

      expect(result.result).to eq('pass')
    end

    it 'fails if the access token request is rejected' do
      stub_request(:post, bulk_token_endpoint)
        .with(body: body)
        .to_return(status: 400, body: '', headers: {})

      allow_any_instance_of(described_class).to receive(:create_client_assertion).and_return(client_assertion)
      result = run(runnable, default_input)

      expect(result.result).to eq('fail')
    end
  end

  describe 'Authorization request response body contains required information test' do
    let(:runnable) { group.tests[5] }
    let!(:response_body) do
      {
        'access_token' => 'its_the_token',
        'token_type' => 'its_a_token',
        'expires_in' => 'a_couple_minutes',
        'scope' => 'system'
      } 
    end

    it 'fails when no authentication response received' do 
      result = run(runnable)

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('No authentication response received.')
    end 

    it 'fails when authentication response is invalid JSON' do 
      result = run(runnable, {authentication_response: '{/}'})
      
      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Invalid JSON. ')
    end 

    it 'fails when authentication response does not contain access_token' do
      result = run(runnable, {authentication_response: "{\"response_body\":\"post\"}"})
      
      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Token response did not contain access_token as required')
    end

    it 'fails when access_token is present but does not contain required keys' do
      missing_key_auth_response = { 'access_token' => 'its_the_token' }
      result = run(runnable, {authentication_response: missing_key_auth_response.to_json})

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Token response did not contain token_type as required')
    end

    it 'passes when access_token is present and contains the required keys' do
      result = run(runnable, {authentication_response: response_body.to_json})
      
      expect(result.result).to eq('pass')
    end
  end
end