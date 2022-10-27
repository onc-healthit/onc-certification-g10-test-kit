require_relative '../../lib/onc_certification_g10_test_kit/resource_access_test'

RSpec.describe ONCCertificationG10TestKit::ResourceAccessTest do
  def run(runnable, inputs = {})
    test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
    test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
    inputs.each do |name, value|
      session_data_repo.save(
        test_session_id: test_session.id,
        name:,
        value:,
        type: runnable.config.input_type(name).presence || 'text'
      )
    end
    Inferno::TestRunner.new(test_session:, test_run:).run(runnable)
  end

  let(:test) do
    Class.new(ONCCertificationG10TestKit::ResourceAccessTest) do
      fhir_client do
        url 'http://example.com/fhir'
        oauth_credentials :smart_credentials
      end

      def resource_group
        USCoreTestKit::USCoreV311::AllergyIntoleranceGroup
      end

      input :smart_credentials, type: :oauth_credentials
    end
  end

  let(:test_session) { repo_create(:test_session, test_suite_id: 'g10_certification') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:url) { 'http://example.com/fhir' }
  let(:patient_id) { '123' }
  let(:smart_credentials) do
    {
      access_token: 'ACCESS_TOKEN',
      refresh_token: 'REFRESH_TOKEN',
      expires_in: 3600,
      client_id: 'CLIENT_ID',
      token_retrieval_time: Time.now.iso8601,
      token_url: 'http://example.com/token'
    }.to_json
  end
  let(:base_inputs) do
    {
      url:,
      patient_id:,
      smart_credentials:
    }
  end

  context 'when the request should succeed' do
    it 'passes if a 200 is received' do
      search_request =
        stub_request(:get, "#{base_inputs[:url]}/AllergyIntolerance?patient=#{patient_id}")
          .to_return(status: 200)

      result = run(test, base_inputs.merge(received_scopes: 'launch/patient'))

      expect(result.result).to eq('pass')
      expect(search_request).to have_been_made
    end

    it 'fails if a 400 is received without an OperationOutcome' do
      search_request =
        stub_request(:get, "#{base_inputs[:url]}/AllergyIntolerance?patient=#{patient_id}")
          .to_return(status: 400, body: FHIR::Bundle.new(id: 'abc').to_json)

      result = run(test, base_inputs.merge(received_scopes: 'launch/patient'))

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/OperationOutcome/)
      expect(search_request).to have_been_made
    end

    it 'passes if a search with status succeeds after a 400 with an OperationOutcome' do
      initial_search_request =
        stub_request(:get, "#{base_inputs[:url]}/AllergyIntolerance?patient=#{patient_id}")
          .to_return(status: 400, body: FHIR::OperationOutcome.new(id: 'abc').to_json)
      status_search_request =
        stub_request(:get, "#{base_inputs[:url]}/AllergyIntolerance?patient=#{patient_id}&clinical-status=active")
          .to_return(status: 200)

      result = run(test, base_inputs.merge(received_scopes: 'launch/patient'))

      expect(result.result).to eq('pass')
      expect(initial_search_request).to have_been_made
      expect(status_search_request).to have_been_made
    end
  end

  context 'when the request should fail' do
    before do
      allow_any_instance_of(test).to receive(:request_should_succeed?).and_return(false)
    end

    it 'fails if a 200 is received' do
      search_request =
        stub_request(:get, "#{base_inputs[:url]}/AllergyIntolerance?patient=#{patient_id}")
          .to_return(status: 200)

      result = run(test, base_inputs.merge(received_scopes: 'launch/patient'))

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/401/)
      expect(search_request).to have_been_made
    end

    it 'passes if a 401 is received' do
      search_request =
        stub_request(:get, "#{base_inputs[:url]}/AllergyIntolerance?patient=#{patient_id}")
          .to_return(status: 401)

      result = run(test, base_inputs.merge(received_scopes: 'launch/patient'))

      expect(result.result).to eq('pass')
      expect(search_request).to have_been_made
    end
  end
end
