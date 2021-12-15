require_relative '../../lib/multi_patient_api/bulk_data_group_export_validation.rb'
require_relative '../../lib/multi_patient_api/bulk_data_utils.rb'

RSpec.describe MultiPatientAPI::BulkDataGroupExportValidation do 
  include BulkDataUtils

  let(:suite) { Inferno::Repositories::TestSuites.new.find('multi_patient_api') }
  let(:group) { Inferno::Repositories::TestGroups.new.find('bulk_data_group_export_validation') }
  let(:input) {  }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: 'multi_patient_api') }

  def run(runnable, inputs = {})
    test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
    test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
    inputs.each do |name, value|
      session_data_repo.save(test_session_id: test_session.id, name: name, value: value)
    end
    Inferno::TestRunner.new(test_session: test_session, test_run: test_run).run(runnable)
  end

  # TODO: Write unit tests after TLS tester class has been implemented.
  describe 'tls endpoint test' do
  end 

  describe '[NDJSON download requires access token] test' do
    it 'skips when requiresAccessToken is not provided' do

    end 
    it 'skips when requiresAccessToken is false' do

    end 
    it 'skips when bulk_status_output is not provided' do

    end 
    context 'when requiresAccessToken is true and bulk_status_output is provided' do
      it 'fails when endpoint can be accessed without token' do

      end 
      it 'passes when endpoint can not be accessed without token' do

      end 
    end 
  end 

  describe '[Patient resources returned conform to US Core Patient Profile] test' do
    it 'skips when bulk_status_output is not provided' do

    end 
    it 'skips when no Patient resource file item returned by server' do

    end 
    it 'fails when returned recources are not profile-conformant' do 

    end 

    it 'passes when returned resources are profile-conformant' do
    end 
  end 

  describe '[Group export has at least two patients]' do 

  end 

  describe '[Patient IDs match those expected in Group]' do
    
  end

  describe '' do
    
  end
end 