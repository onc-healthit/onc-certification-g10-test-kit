RSpec.describe ONCCertificationG10TestKit::PatientScopeTest do
  def run(runnable, inputs = {})
    test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
    test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
    inputs.each do |name, value|
      session_data_repo.save(
        test_session_id: test_session.id,
        name:,
        value:,
        type: runnable.config.input_type(name)
      )
    end
    Inferno::TestRunner.new(test_session:, test_run:).run(runnable)
  end

  let(:suite_id) { 'g10_certification' }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test) { described_class }

  context 'with v1 scopes' do
    let(:received_scopes) { 'launch openid fhirUser patient/Patient.read' }

    it 'passes when a patient scope is received' do
      result = run(test, received_scopes:)

      expect(result.result).to eq('pass')
    end

    it 'fails when a patient scope is not received' do
      received_scopes.gsub!('patient/', 'user/')
      result = run(test, received_scopes:)

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/No scope matching/)
    end
  end

  context 'with v2 scopes' do
    let(:received_scopes) { 'launch openid fhirUser patient/Patient.rs' }

    before do
      allow_any_instance_of(test).to receive(:scope_version).and_return(:v2)
    end

    it 'passes when patient read and search scopes are received together' do
      result = run(test, received_scopes:)

      expect(result.result).to eq('pass')
    end

    it 'passes when patient read and search scopes are received separately' do
      received_scopes.gsub!('.rs', '.r')
      received_scopes.concat(' patient/Patient.s')

      result = run(test, received_scopes:)

      expect(result.result).to eq('pass')
    end

    it 'fails when a patient read and search scopes are not received' do
      received_scopes.gsub!('patient/', 'user/')
      result = run(test, received_scopes:)

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/No scope matching/)
    end

    it 'fails if both read and search scopes are not received' do
      received_scopes.gsub!('.rs', '.r')

      result = run(test, received_scopes:)

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/No scope matching/)
    end
  end
end
