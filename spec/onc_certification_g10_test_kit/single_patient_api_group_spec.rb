RSpec.describe ONCCertificationG10TestKit::SinglePatientAPIGroup do
  let(:suite_id) { 'g10_certification' }

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
