RSpec.describe ONCCertificationG10TestKit::SinglePatientAPIGroup do
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
  let(:test_session) { repo_create(:test_session, test_suite_id: suite_id) }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }

  describe 'setup test' do
    let(:test) { described_class.tests.first }

    it 'does not raise an error when additional_patient_ids is not provided' do
      result = run(test, patient_id: '85', url: 'foo')

      expect(result.result).to eq('pass')
    end

    it 'outputs the correct patient_ids when additional_patient_ids is not provided' do
      run(test, patient_id: '85', url: 'foo')
      patient_ids = session_data_repo.load(test_session_id: test_session.id, name: 'patient_ids')

      expect(patient_ids).to eq('85')
    end

    it 'outputs the correct patient_ids when additional_patient_ids are provided' do
      run(test, patient_id: '85', additional_patient_ids: '85 , 123,, , 456 ,789', url: 'foo')
      patient_ids = session_data_repo.load(test_session_id: test_session.id, name: 'patient_ids')

      expect(patient_ids).to eq('85,123,456,789')
    end
  end
end
