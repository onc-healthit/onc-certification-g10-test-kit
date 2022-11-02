RSpec.describe ONCCertificationG10TestKit::SMARTEHRPatientLaunchGroupSTU2 do # rubocop:disable RSpec/FilePath
  def run(runnable, inputs = {})
    test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
    test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
    inputs.each do |name, value|
      session_data_repo.save(
        test_session_id: test_session.id,
        name: name,
        value: value,
        type: runnable.config.input_type(name) || 'text'
      )
    end
    Inferno::TestRunner.new(test_session: test_session, test_run: test_run).run(runnable)
  end

  let(:test_session) { repo_create(:test_session, test_suite_id: 'g10_certification') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test) do
    described_class.tests.find { |test| test.id.to_s.end_with? 'g10_patient_scope' }
  end

  describe 'scopes test' do
    it 'fails if patient-level scopes are not received' do
      repo_create(:request, test_session_id: test_session.id, name: :ehr_patient_token, status: 200)
      result =
        run(
          test,
          ehr_patient_received_scopes: 'launch openid fhirUser offline_access user/Patient.rs'
        )

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(%r{patient/Patient\.rs scope was requested, but not received.})
    end

    it 'passes if patient-level scopes are received' do
      repo_create(:request, test_session_id: test_session.id, name: :ehr_patient_token, status: 200)
      result =
        run(
          test,
          ehr_patient_received_scopes: 'launch openid fhirUser offline_access patient/Patient.rs'
        )

      expect(result.result).to eq('pass')
    end
  end
end
