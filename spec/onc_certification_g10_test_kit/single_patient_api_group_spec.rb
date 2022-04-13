RSpec.describe ONCCertificationG10TestKit::SinglePatientAPIGroup do
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

  let(:test_session) { repo_create(:test_session, test_suite_id: 'g10_certification') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }

  describe 'setup test' do
    let(:test) { described_class.tests.first }

    it 'does not raise an error when additional_patient_ids is not provided' do
      result = run(test, patient_id: '85')

      expect(result.result).to eq('pass')
    end
  end
end
