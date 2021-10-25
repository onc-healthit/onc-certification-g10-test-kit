RSpec.describe InfernoTemplate::PatientGroup do
  let(:suite) { Inferno::Repositories::TestSuites.new.find('test_suite_template') }
  let(:group) { suite.groups[1] }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: 'test_suite_template') }
  let(:url) { 'http://example.com/fhir' }
  let(:error_outcome) { FHIR::OperationOutcome.new(issue: [{ severity: 'error' }]) }

  def run(runnable, inputs = {})
    test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
    test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
    inputs.each do |name, value|
      session_data_repo.save(test_session_id: test_session.id, name: name, value: value)
    end
    Inferno::TestRunner.new(test_session: test_session, test_run: test_run).run(runnable)
  end

  describe 'read test' do
    let(:test) { group.tests.first }
    let(:patient_id) { 'abc123' }

    it 'passes if a Patient was received' do
      resource = FHIR::Patient.new(id: patient_id)
      stub_request(:get, "#{url}/Patient/#{patient_id}")
        .to_return(status: 200, body: resource.to_json)

      result = run(test, url: url, patient_id: patient_id)

      expect(result.result).to eq('pass')
    end

    it 'fails if a 200 is not received' do
      resource = FHIR::Patient.new(id: patient_id)
      stub_request(:get, "#{url}/Patient/#{patient_id}")
        .to_return(status: 201, body: resource.to_json)

      result = run(test, url: url, patient_id: patient_id)

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/200/)
    end

    it 'fails if a Patient is not received' do
      resource = FHIR::Condition.new(id: patient_id)
      stub_request(:get, "#{url}/Patient/#{patient_id}")
        .to_return(status: 200, body: resource.to_json)

      result = run(test, url: url, patient_id: patient_id)

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/Patient/)
    end

    it 'fails if the id received does not match the one requested' do
      resource = FHIR::Patient.new(id: '456')
      stub_request(:get, "#{url}/Patient/#{patient_id}")
        .to_return(status: 200, body: resource.to_json)

      result = run(test, url: url, patient_id: patient_id)

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/resource with id/)
    end
  end

  describe 'validation test' do
    let(:test) { group.tests.last }

    it 'passes if the resource is valid' do
      stub_request(:post, "#{ENV.fetch('VALIDATOR_URL')}/validate")
        .with(query: hash_including({}))
        .to_return(status: 200, body: FHIR::OperationOutcome.new.to_json)

      resource = FHIR::Patient.new
      repo_create(
        :request,
        name: :patient,
        test_session_id: test_session.id,
        response_body: resource.to_json
      )

      result = run(test)

      expect(result.result).to eq('pass')
    end

    it 'fails if the resource is not valid' do
      stub_request(:post, "#{ENV.fetch('VALIDATOR_URL')}/validate")
        .with(query: hash_including({}))
        .to_return(status: 200, body: error_outcome.to_json)

      resource = FHIR::Patient.new
      repo_create(
        :request,
        name: :patient,
        test_session_id: test_session.id,
        response_body: resource.to_json
      )

      result = run(test)

      expect(result.result).to eq('fail')
    end
  end
end
