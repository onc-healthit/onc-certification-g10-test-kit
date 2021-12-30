require_relative '../../lib/multi_patient_api/bulk_data_group_export_validation.rb'
require_relative '../../lib/multi_patient_api/bulk_data_utils.rb'
require 'NDJSON'

include ValidationUtils

RSpec.describe MultiPatientAPI::BulkDataGroupExportValidation do 

  let(:group) { Inferno::Repositories::TestGroups.new.find('bulk_data_group_export_validation') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_group_id: 'bulk_data_group_export_validation') }
  let(:endpoint) { 'https://www.example.com' }
  let(:status_output) { "[{\"url\":\"#{endpoint}\"}]" }
  let(:bearer_token) { 'token' }
  let(:headers) { { 'Content-Type' => 'application/fhir+ndjson' } }
  let(:contents) { String.new }
  let(:contents_missing_element) { String.new }
  let(:scratch) { {} }
  let(:input) do 
    { requires_access_token: true,
      status_output: status_output,
      bearer_token: bearer_token
    }
  end 

  def run(runnable, inputs = {})
    test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
    test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
    inputs.each do |name, value|
      session_data_repo.save(test_session_id: test_session.id, name: name, value: value)
    end

    Inferno::TestRunner.new(test_session: test_session, test_run: test_run).run(runnable, scratch)
  end

  # TODO: Write unit tests after TLS tester class has been implemented.
  describe 'tls endpoint test' do

  end 

  describe '[NDJSON download requires access token] test' do
    let(:runnable) { group.tests[1] }

    it 'skips when status_ouput is not provided' do
      result = run(runnable)

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('Could not verify this functionality when Bulk Status Output is not provided')
    end

    it 'skips when requires_access_token is not provided' do
      result = run(runnable, { status_output: status_output })

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('Could not verify this functionality when requiresAccessToken is not provided')
    end 

    # it 'skips when requiresAccessToken is false' do
    #   result = run(runnable, { requires_access_token: false, status_output: status_output })

    #   expect(result.result).to eq('skip')
    #   expect(result.result_message).to eq('Could not verify this functionality when requireAccessToken is false')
    # end 

    it 'skips when bearer_token is not provided' do
      result = run(runnable, { requires_access_token: true, status_output: status_output })

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('Could not verify this functionality when Bearer Token is not provided')
    end 

    context 'when status_output and bearer_token are given and requiresAccessToken is true' do
      it 'fails if endpoint can be accessed without token' do
        stub_request(:get, endpoint)
          .to_return(status: 200)

        result = run(runnable, input)

        expect(result.result).to eq('fail')
        expect(result.result_message).to eq('Bad response status: expected 400, 401, but received 200')
      end 

      it 'passes if endpoint can not be accessed without token' do
        stub_request(:get, endpoint)
          .to_return(status: 400)

        result = run(runnable, input)

        expect(result.result).to eq('pass')
      end 
    end 
  end 

  describe '[Patient resources returned conform to US Core Patient Profile] test' do
    let(:runnable) { group.tests[2] }
    let(:resources) { NDJSON::Parser.new('spec/multi_patient_api/resources/Patient.ndjson') }
    let(:patient_input) do 
      input.merge({ status_output: "[{\"url\":\"#{endpoint}\",\"type\":\"Patient\",\"count\":2}]" })
    end 
    let(:not_patient_input) do
      input.merge({ status_output: "[{\"url\":\"#{endpoint}\",\"type\":\"Location\",\"count\":2}]" })
    end
    before do
      resources.each do |resource|
        contents << resource.to_json + "\n"
        resource["identifier"] = nil
        contents_missing_element << (resource.to_json.gsub /[ \n]/, '') + "\n"
      end 
    end
    
    it 'skips when status_output is not provided' do
      result = run(runnable)

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('Could not verify this functionality when Bulk Status Output is not provided')
    end 

    it 'skips when requires_access_token is not provided' do
      result = run(runnable, { status_output: status_output })

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('Could not verify this functionality when requiresAccessToken is not provided')
    end 

    it 'skips when bearer_token is not provided' do
      result = run(runnable, { requires_access_token: true, status_output: status_output })

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('Could not verify this functionality when Bearer Token is required and not provided')
    end 

    it 'skips when no Patient resource file item returned by server' do
      result = run(runnable, not_patient_input)

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('No Patient resource file item returned by server.')
    end 
    
    it 'skips when returned resources are missing a must support element' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept'=>'application/fhir+ndjson' })
        .to_return(status: 200, body: contents_missing_element, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, patient_input)

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('Could not find identifier, identifier.system, identifier.value, Patient.extension:race, Patient.extension:ethnicity, Patient.extension:birthsex in the 2 provided Patient resource(s)')
    end

    it 'passes when returned resources are fully conformant to the patient profile' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept'=>'application/fhir+ndjson' })
        .to_return(status: 200, body: contents, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, patient_input)

      expect(result.result).to eq('pass')
    end
  end 

  describe '[Group export has at least two patients]' do 
    let(:runnable) { group.tests[3] }

    it 'skips when no patient ids have been stored' do
      result = run(runnable)

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('No Patient resources processed from bulk data export.')
    end 

    it 'fails when less than two patient ids are stored' do 
      scratch[:patient_ids_seen] = ['one_id']
      result = run(runnable)

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Bulk data export did not have multiple Patient resources.')
    end 

    it 'passes when two or more patient ids are stored' do
      scratch[:patient_ids_seen] = ['one_id', 'two_id']
      result = run(runnable)

      expect(result.result).to eq('pass')
    end
  end 

  describe '[Patient IDs match those expected in Group]' do
    let(:runnable) { group.tests[4] }
    let(:input) { { bulk_patient_ids_in_group: "one_id, two_id, three_id" } }

    it 'omits when no patient ids have been stored' do
      result = run(runnable)

      expect(result.result).to eq('omit')
      expect(result.result_message).to eq('No patient ids were given.')
    end

    it 'fails when the input patient ids do not match those stored' do
      scratch[:patient_ids_seen] = ['one_id', 'one_id', 'one_id']
      result = run(runnable, input)

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Mismatch between patient ids seen (one_id, one_id, one_id) and patient ids expected (one_id, two_id, three_id)')
    end

    it 'fails when more input patient ids than ids stored' do
      scratch[:patient_ids_seen] = ['one_id', 'two_id']
      result = run(runnable, input)

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Mismatch between patient ids seen (one_id, two_id) and patient ids expected (one_id, two_id, three_id)')
    end

    it 'fails when less input patient ids than ids stored' do
      scratch[:patient_ids_seen] = ['one_id', 'two_id', 'three_id', 'four_id']
      result = run(runnable, input)

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Mismatch between patient ids seen (one_id, two_id, three_id, four_id) and patient ids expected (one_id, two_id, three_id)')
    end

    it 'passes when the input patient ids do not match those stored' do
      scratch[:patient_ids_seen] = ['one_id', 'two_id', 'three_id']
      result = run(runnable, input)

      expect(result.result).to eq('pass')
    end
  end

  describe '[AllergyIntolerance resources returned conform to the US Core AllergyIntolerance Profile] test' do
    let(:runnable) { group.tests[5] }
    let(:resources) { NDJSON::Parser.new("spec/multi_patient_api/resources/AllergyIntolerance.ndjson") }
    let(:allergy_input) do 
      input.merge({ status_output: "[{\"url\":\"https://www.example.com\",\"type\":\"AllergyIntolerance\",\"count\":10}]" })
    end 
    before do
      resources.each do |resource|
        contents << resource.to_json + "\n"
        resource["clinicalStatus"] = nil
        contents_missing_element << (resource.to_json.gsub /[ \n]/, '') + "\n"
      end 
    end

    it 'skips when returned resources are missing a must support element' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept'=>'application/fhir+ndjson' })
        .to_return(status: 200, body: contents_missing_element, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, allergy_input)

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('Could not find clinicalStatus in the 10 provided AllergyIntolerance resource(s)')
    end

    it 'passes when returned resources are fully conformant to the patient profile' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept'=>'application/fhir+ndjson' })
        .to_return(status: 200, body: contents, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, allergy_input)

      expect(result.result).to eq('pass')
    end
  end

  describe '[CarePlan resources returned conform to the US Core CarePlan Profile] test' do
    let(:runnable) { group.tests[6] }
    let(:resources) { NDJSON::Parser.new("spec/multi_patient_api/resources/CarePlan.ndjson") }
    let(:careplan_input) do 
        input.merge({ status_output: "[{\"url\":\"https://www.example.com\",\"type\":\"CarePlan\",\"count\":26}]" })
    end 
    let(:contents_missing_slice) { String.new }
    before do
      resources.each do |resource|
        contents << resource.to_json + "\n"
        resource["text"]["status"] = nil
        contents_missing_element << (resource.to_json.gsub /[ \n]/, '') + "\n"
      end 
      contents.lines.each do |resource|
        fhir_resource = FHIR.from_contents(resource)
        fhir_resource.category = fhir_resource.category.filter_map { |x| x if x.coding.none? { |y| y.code == 'assess-plan' } }
        contents_missing_slice << (fhir_resource.to_json.gsub /[ \n]/, '') + "\n"
      end 
    end

    it 'skips when returned resources are missing a must support element' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept'=>'application/fhir+ndjson' })
        .to_return(status: 200, body: contents_missing_element, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, careplan_input)

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('Could not find text.status in the 26 provided CarePlan resource(s)')
    end

    it 'skips when returned resources are missing a must support slice' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept'=>'application/fhir+ndjson' })
        .to_return(status: 200, body: contents_missing_slice, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, careplan_input)

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('Could not find CarePlan.category:AssessPlan in the 26 provided CarePlan resource(s)')
    end

    it 'passes when returned resources are fully conformant to the patient profile' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept'=>'application/fhir+ndjson' })
        .to_return(status: 200, body: contents, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, careplan_input)

      expect(result.result).to eq('pass')
    end
  end

  describe '[DiagnosticReport resources returned conform to the US Core DiagnosticReport Profile] test' do
    let(:runnable) { group.tests[10] }
    let(:resources) { NDJSON::Parser.new("spec/multi_patient_api/resources/DiagnosticReport.ndjson") }
    let(:diagnostic_input) do 
      input.merge({ status_output: "[{\"url\":\"https://www.example.com\",\"type\":\"DiagnosticReport\",\"count\":43}]" })
    end 
    let(:contents_missing_lab) { String.new }
    let(:contents_missing_note) { String.new }
    before do
      resources.each { |r| contents << r.to_json + "\n" }
      contents.lines.each do |resource|
        fhir_resource = FHIR.from_contents(resource)
        if fhir_resource.meta.profile[0] == "http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-note"
          fhir_resource.result = nil # Without result set to nil, note resources also conform to lab
          contents_missing_lab << (fhir_resource.to_json.gsub /[ \n]/, '') + "\n" 
        elsif fhir_resource.meta.profile[0] == "http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-lab"
          fhir_resource.encounter = nil # Without encounter set to nil, lab resources also conform to note
          contents_missing_note << (fhir_resource.to_json.gsub /[ \n]/, '') + "\n"
        end 
      end
    end

    it 'skips without DiagnosticReport Lab resources' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept'=>'application/fhir+ndjson' })
        .to_return(status: 200, body: contents_missing_lab, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, diagnostic_input)

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('No DiagnosticReport resources found that conform to profile: http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-lab.')
    end

    it 'skips without DiagnosticReport Note resources' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept'=>'application/fhir+ndjson' })
        .to_return(status: 200, body: contents_missing_note, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, diagnostic_input)

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('No DiagnosticReport resources found that conform to profile: http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-note.')
    end

    it 'passes with both DiagnosticReport Lab and Note metadata' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept'=>'application/fhir+ndjson' })
        .to_return(status: 200, body: contents, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, diagnostic_input)

      expect(result.result).to eq('pass')
    end
  end

  describe '[Observation resources returned conform to the US Core Observation Profile] test' do
    let(:runnable) { group.tests[15] }
    let(:resources) { NDJSON::Parser.new("spec/multi_patient_api/resources/Observation.ndjson") }
    let(:observation_input) do 
      input.merge({ status_output: "[{\"url\":\"https://www.example.com\",\"type\":\"Observation\",\"count\":174}]" })
    end 
    let(:contents_missing_pediatricbmi) { String.new }
    let(:contents_missing_smokingstatus) { String.new }
    let(:contents_missing_bodyheight) { String.new }
    let(:contents_missing_resprate) { String.new }
    before do
      resources.each { |r| contents << r.to_json + "\n" }
      contents.lines.each do |resource|
        fhir_resource = FHIR.from_contents(resource)
        contents_missing_pediatricbmi << (fhir_resource.to_json.gsub /[ \n]/, '') + "\n" unless fhir_resource.meta.profile[0] == 'http://hl7.org/fhir/us/core/StructureDefinition/pediatric-bmi-for-age'
        contents_missing_smokingstatus << (fhir_resource.to_json.gsub /[ \n]/, '') + "\n"  unless fhir_resource.meta.profile[0] == 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-smokingstatus'
        contents_missing_bodyheight << (fhir_resource.to_json.gsub /[ \n]/, '') + "\n" unless fhir_resource.meta.profile[0] == 'http://hl7.org/fhir/StructureDefinition/bodyheight'
        contents_missing_resprate << (fhir_resource.to_json.gsub /[ \n]/, '') + "\n"  unless fhir_resource.meta.profile[0] == 'http://hl7.org/fhir/StructureDefinition/resprate'
      end 
    end

    it 'skips without PediatricBmiForAgeGroup resources' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept'=>'application/fhir+ndjson' })
        .to_return(status: 200, body: contents_missing_pediatricbmi, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, observation_input)

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('No Observation resources found that conform to profile: http://hl7.org/fhir/us/core/StructureDefinition/pediatric-bmi-for-age.')
    end

    it 'skips without SmokingStatusGroup resources' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept'=>'application/fhir+ndjson' })
        .to_return(status: 200, body: contents_missing_smokingstatus, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, observation_input)

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('No Observation resources found that conform to profile: http://hl7.org/fhir/us/core/StructureDefinition/us-core-smokingstatus.')
    end

    it 'skips without Bodyheight resources' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept'=>'application/fhir+ndjson' })
        .to_return(status: 200, body: contents_missing_bodyheight, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, observation_input)

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('No Observation resources found that conform to profile: http://hl7.org/fhir/StructureDefinition/bodyheight.')
    end

    it 'skips without Resprate resources' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept'=>'application/fhir+ndjson' })
        .to_return(status: 200, body: contents_missing_resprate, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, observation_input)

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('No Observation resources found that conform to profile: http://hl7.org/fhir/StructureDefinition/resprate.')
    end

    it 'skips if lines_to_validate does not include enough resources to verify profile conformance' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept'=>'application/fhir+ndjson' })
        .to_return(status: 200, body: contents, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)

      result = run(runnable, observation_input.merge(lines_to_validate: 75))

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('No Observation resources found that conform to profile: http://hl7.org/fhir/us/core/StructureDefinition/us-core-observation-lab.')
    end

    it 'passes with all possible resources included in the Observation Profile' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept'=>'application/fhir+ndjson' })
        .to_return(status: 200, body: contents, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, observation_input)

      expect(result.result).to eq('pass')
    end
  end
end 