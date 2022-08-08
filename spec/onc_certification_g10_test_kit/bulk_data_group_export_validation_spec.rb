require_relative '../../lib/onc_certification_g10_test_kit/bulk_data_group_export_validation'
require 'ndjson'

RSpec.describe ONCCertificationG10TestKit::BulkDataGroupExportValidation do
  let(:group) do
    ONCCertificationG10TestKit::G10CertificationSuite.groups
      .find { |group| group.id.include? 'multi_patient_api' }
      .groups.find { |group| group.id.include? 'bulk_data_group_export_validation' }
  end
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: 'g10_certification') }
  let(:endpoint) { 'https://www.example.com' }
  let(:status_output) { "[{\"url\":\"#{endpoint}\"}]" }
  let(:bearer_token) { 'token' }
  let(:headers) { { 'Content-Type' => 'application/fhir+ndjson' } }
  let(:contents) { String.new }
  let(:contents_missing_element) { String.new }
  let(:scratch) { {} }
  let(:input) do
    {
      requires_access_token: 'true',
      status_output: status_output,
      bearer_token: bearer_token
    }
  end

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

    Inferno::TestRunner.new(test_session: test_session, test_run: test_run).run(runnable, scratch)
  end

  describe '[NDJSON download requires access token] test' do
    let(:runnable) { group.tests[1] }

    it 'skips when bulk_download_url is not provided' do
      result = run(runnable)

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('Could not verify this functionality when no download link was provided')
    end

    it 'skips when requires_access_token is not provided' do
      result = run(runnable, { bulk_download_url: endpoint })

      expect(result.result).to eq('skip')
      expect(result.result_message)
        .to eq('Could not verify this functionality when requiresAccessToken is not provided')
    end

    it 'omits when requiresAccessToken is false' do
      result = run(runnable, { requires_access_token: 'false', bulk_download_url: endpoint })

      expect(result.result).to eq('omit')
      expect(result.result_message).to eq('Could not verify this functionality when requiresAccessToken is false')
    end

    it 'skips when bearer_token is not provided' do
      result = run(runnable, { requires_access_token: 'true', bulk_download_url: endpoint })

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('Could not verify this functionality when Bearer Token is not provided')
    end

    context 'when bulk_download_url and bearer_token are given and requiresAccessToken is true' do
      it 'fails if endpoint can be accessed without token' do
        stub_request(:get, endpoint)
          .to_return(status: 200)

        result = run(runnable, input.merge(bulk_download_url: endpoint))

        expect(result.result).to eq('fail')
        expect(result.result_message).to eq('Bad response status: expected 400, 401, but received 200')
      end

      it 'passes if endpoint can not be accessed without token' do
        stub_request(:get, endpoint)
          .to_return(status: 400)

        result = run(runnable, input.merge(bulk_download_url: endpoint))

        expect(result.result).to eq('pass')
      end
    end
  end

  describe '[Patient resources returned conform to US Core Patient Profile] test' do
    let(:runnable) { group.tests[2] }
    let(:resources) { NDJSON::Parser.new('spec/fixtures/Patient.ndjson') }
    let(:count) { 2 }
    let(:patient_input) do
      input.merge({ status_output: "[{\"url\":\"#{endpoint}\",\"type\":\"Patient\",\"count\":#{count}}]" })
    end
    let(:patient_input_two_files) do
      input.merge(
        {
          status_output: "[{\"url\":\"#{endpoint}\",\"type\":\"Patient\",\"count\":#{count}}," \
                         "{\"url\":\"#{endpoint}/2\",\"type\":\"Patient\",\"count\":#{count}}]"
        }
      )
    end
    let(:operation_outcome_no_name) do
      FHIR::OperationOutcome.new(
        issue: [
          {
            severity: 'error',
            code: 'required',
            details: {
              text: 'Patient.name: minimum required = 1, but only found 0'
            },
            expression: [
              'Patient'
            ]
          }
        ]
      )
    end
    let(:validator_url) { runnable.find_validator(:default).url }

    before do
      resources.each do |resource|
        contents << ("#{resource.to_json}\n")
        resource['identifier'] = nil
        contents_missing_element << ("#{resource.to_json.gsub(/[ \n]/, '')}\n")
      end
    end

    it 'skips when returned resources are missing a must support element' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept' => 'application/fhir+ndjson' })
        .to_return(status: 200, body: contents_missing_element, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, patient_input)

      expect(result.result).to eq('skip')
      expect(result.result_message)
        .to eq('Could not find identifier, identifier.system, identifier.value ' \
               'in the 2 provided Patient resource(s)')
    end

    it 'passes when returned resources are fully conformant to the patient profile' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept' => 'application/fhir+ndjson' })
        .to_return(status: 200, body: contents, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, patient_input)

      expect(result.result).to eq('pass')
    end

    it 'passes when returned multiple files and are fully conformant to the patient profile' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept' => 'application/fhir+ndjson' })
        .to_return(status: 200, body: contents_missing_element, headers: headers)
      stub_request(:get, "#{endpoint}/2")
        .with(headers: { 'Accept' => 'application/fhir+ndjson' })
        .to_return(status: 200, body: contents, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, patient_input_two_files)

      expect(result.result).to eq('pass')
    end

    it 'validates all lines and saves errors for the first failed line' do
      stub_request(:get, endpoint.to_s)
        .with(headers: { 'Accept' => 'application/fhir+ndjson' })
        .to_return(status: 200, body: contents, headers: headers)

      validation_request = stub_request(:post, "#{validator_url}/validate?profile=http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient|3.1.1")
        .to_return(status: 200, body: operation_outcome_no_name.to_json)

      result = run(runnable, patient_input)

      messages = Inferno::Repositories::Messages.new.messages_for_result(result.id)

      expect(validation_request).to have_been_made.twice
      expect(result.result).to eq('fail')
      expect(result.result_message).to start_with('2 / 2 Patient resources failed profile validation')
      expect(messages.count { |message| message.type == 'error' }).to be(1)
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
    let(:input) { { bulk_patient_ids_in_group: 'one_id, two_id, three_id' } }

    it 'omits when no patient ids have been stored' do
      result = run(runnable)

      expect(result.result).to eq('omit')
      expect(result.result_message).to eq('No patient ids were given.')
    end

    it 'fails when the input patient ids do not match those stored' do
      scratch[:patient_ids_seen] = ['one_id', 'one_id', 'one_id']
      result = run(runnable, input)

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Mismatch between patient ids seen (one_id, one_id, one_id) and patient ' \
                                          'ids expected (one_id, two_id, three_id)')
    end

    it 'fails when more input patient ids than ids stored' do
      scratch[:patient_ids_seen] = ['one_id', 'two_id']
      result = run(runnable, input)

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Mismatch between patient ids seen (one_id, two_id) and patient ' \
                                          'ids expected (one_id, two_id, three_id)')
    end

    it 'fails when less input patient ids than ids stored' do
      scratch[:patient_ids_seen] = ['one_id', 'two_id', 'three_id', 'four_id']
      result = run(runnable, input)

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Mismatch between patient ids seen (one_id, two_id, three_id, four_id) ' \
                                          'and patient ids expected (one_id, two_id, three_id)')
    end

    it 'passes when the input patient ids do not match those stored' do
      scratch[:patient_ids_seen] = ['one_id', 'two_id', 'three_id']
      result = run(runnable, input)

      expect(result.result).to eq('pass')
    end
  end

  describe '[AllergyIntolerance resources returned conform to the US Core AllergyIntolerance Profile] test' do
    let(:runnable) { group.tests[5] }
    let(:resources) { NDJSON::Parser.new('spec/fixtures/AllergyIntolerance.ndjson') }
    let(:allergy_input) do
      input.merge({ status_output: '[{"url":"https://www.example.com","type":"AllergyIntolerance","count":10}]' })
    end

    before do
      resources.each do |resource|
        contents << ("#{resource.to_json}\n")
        resource['clinicalStatus'] = nil
        contents_missing_element << ("#{resource.to_json.gsub(/[ \n]/, '')}\n")
      end
    end

    it 'skips when returned resources are missing a must support element' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept' => 'application/fhir+ndjson' })
        .to_return(status: 200, body: contents_missing_element, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, allergy_input)

      expect(result.result).to eq('skip')
      expect(result.result_message)
        .to eq('Could not find clinicalStatus in the 10 provided AllergyIntolerance resource(s)')
    end

    it 'passes when returned resources are fully conformant to the allergy profile' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept' => 'application/fhir+ndjson' })
        .to_return(status: 200, body: contents, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, allergy_input)

      expect(result.result).to eq('pass')
    end
  end

  describe '[CarePlan resources returned conform to the US Core CarePlan Profile] test' do
    let(:runnable) { group.tests[6] }
    let(:resources) { NDJSON::Parser.new('spec/fixtures/CarePlan.ndjson') }
    let(:careplan_input) do
      input.merge({ status_output: '[{"url":"https://www.example.com","type":"CarePlan","count":26}]' })
    end
    let(:contents_missing_slice) { String.new }

    before do
      resources.each do |resource|
        contents << ("#{resource.to_json}\n")
        resource['text']['status'] = nil
        contents_missing_element << ("#{resource.to_json.gsub(/[ \n]/, '')}\n")
      end
      contents.lines.each do |resource|
        fhir_resource = FHIR.from_contents(resource)
        fhir_resource.category = fhir_resource.category.filter_map do |x|
          x if x.coding.none? do |y|
                 y.code == 'assess-plan'
               end
        end
        contents_missing_slice << ("#{fhir_resource.to_json.gsub(/[ \n]/, '')}\n")
      end
    end

    it 'skips when returned resources are missing a must support element' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept' => 'application/fhir+ndjson' })
        .to_return(status: 200, body: contents_missing_element, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, careplan_input)

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('Could not find text.status in the 26 provided CarePlan resource(s)')
    end

    it 'skips when returned resources are missing a must support slice' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept' => 'application/fhir+ndjson' })
        .to_return(status: 200, body: contents_missing_slice, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, careplan_input)

      expect(result.result).to eq('skip')
      expect(result.result_message)
        .to eq('Could not find CarePlan.category:AssessPlan in the 26 provided CarePlan resource(s)')
    end

    it 'passes when returned resources are fully conformant to the patient profile' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept' => 'application/fhir+ndjson' })
        .to_return(status: 200, body: contents, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, careplan_input)

      expect(result.result).to eq('pass')
    end
  end

  describe '[DiagnosticReport resources returned conform to the US Core DiagnosticReport Profile] test' do
    let(:runnable) { group.tests[10] }
    let(:resources) { NDJSON::Parser.new('spec/fixtures/DiagnosticReport.ndjson') }
    let(:diagnostic_input) do
      input.merge({ status_output: "[{\"url\":\"#{endpoint}\",\"type\":\"DiagnosticReport\",\"count\":43}]" })
    end
    let(:diagnostic_input_two_files) do
      input.merge(
        {
          status_output: "[{\"url\":\"#{endpoint}\",\"type\":\"DiagnosticReport\",\"count\":43}," \
                         "{\"url\":\"#{endpoint}/2\",\"type\":\"DiagnosticReport\",\"count\":43}]"
        }
      )
    end
    let(:contents_missing_lab) { String.new }
    let(:contents_missing_note) { String.new }
    let(:contents_lab) { String.new }
    let(:contents_note) { String.new }

    before do
      resources.each { |r| contents << ("#{r.to_json}\n") }
      contents.lines.each do |resource|
        fhir_resource = FHIR.from_contents(resource)
        case fhir_resource.meta.profile[0]
        when 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-note'
          fhir_resource.result = nil # Without result set to nil, note resources also conform to lab
          contents_missing_lab << ("#{fhir_resource.to_json.gsub(/[ \n]/, '')}\n")
        when 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-lab'
          fhir_resource.encounter = nil # Without encounter set to nil, lab resources also conform to note
          contents_missing_note << ("#{fhir_resource.to_json.gsub(/[ \n]/, '')}\n")
        end
      end
    end

    it 'skips without DiagnosticReport Lab resources' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept' => 'application/fhir+ndjson' })
        .to_return(status: 200, body: contents_missing_lab, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, diagnostic_input)

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('No DiagnosticReport resources found that conform to profile: http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-lab.')
    end

    it 'skips without DiagnosticReport Note resources' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept' => 'application/fhir+ndjson' })
        .to_return(status: 200, body: contents_missing_note, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, diagnostic_input)

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('No DiagnosticReport resources found that conform to profile: http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-note.')
    end

    it 'passes with both DiagnosticReport Lab and Note metadata' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept' => 'application/fhir+ndjson' })
        .to_return(status: 200, body: contents, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, diagnostic_input)

      expect(result.result).to eq('pass')
    end

    it 'pass with both DiagnosticReport Lab and Note metadata in separated files' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept' => 'application/fhir+ndjson' })
        .to_return(status: 200, body: contents_missing_lab, headers: headers)
      stub_request(:get, "#{endpoint}/2")
        .with(headers: { 'Accept' => 'application/fhir+ndjson' })
        .to_return(status: 200, body: contents_missing_note, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, diagnostic_input_two_files)

      expect(result.result).to eq('pass')
    end
  end

  describe '[Observation resources returned conform to the US Core Observation Profile] test' do
    let(:runnable) { group.tests[15] }
    let(:resources) { NDJSON::Parser.new('spec/fixtures/Observation.ndjson') }
    let(:observation_input) do
      input.merge({ status_output: '[{"url":"https://www.example.com","type":"Observation","count":174}]' })
    end
    let(:contents_missing_pediatricbmi) { String.new }
    let(:contents_missing_smokingstatus) { String.new }
    let(:contents_missing_bodyheight) { String.new }
    let(:contents_missing_resprate) { String.new }
    let(:contents_missing_profile) { String.new }

    before do
      resources.each { |r| contents << ("#{r.to_json}\n") }
      contents.lines.each do |resource|
        fhir_resource = FHIR.from_contents(resource)
        unless fhir_resource.meta.profile[0] == 'http://hl7.org/fhir/us/core/StructureDefinition/pediatric-bmi-for-age'
          contents_missing_pediatricbmi << "#{fhir_resource.to_json.gsub(/[ \n]/, '')}\n"
        end
        unless fhir_resource.meta.profile[0] == 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-smokingstatus'
          contents_missing_smokingstatus << "#{fhir_resource.to_json.gsub(/[ \n]/, '')}\n"
        end
        unless fhir_resource.meta.profile[0] == 'http://hl7.org/fhir/StructureDefinition/bodyheight'
          contents_missing_bodyheight << "#{fhir_resource.to_json.gsub(/[ \n]/, '')}\n"
        end
        unless fhir_resource.meta.profile[0] == 'http://hl7.org/fhir/StructureDefinition/resprate'
          contents_missing_resprate << "#{fhir_resource.to_json.gsub(/[ \n]/, '')}\n"
        end
        fhir_resource.meta.profile = nil
        contents_missing_profile << "#{fhir_resource.to_json.gsub(/[ \n]/, '')}\n"
      end
    end

    it 'skips without PediatricBmiForAgeGroup resources' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept' => 'application/fhir+ndjson' })
        .to_return(status: 200, body: contents_missing_pediatricbmi, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, observation_input)

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('No Observation resources found that conform to profile: http://hl7.org/fhir/us/core/StructureDefinition/pediatric-bmi-for-age.')
    end

    it 'skips without SmokingStatusGroup resources' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept' => 'application/fhir+ndjson' })
        .to_return(status: 200, body: contents_missing_smokingstatus, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, observation_input)

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('No Observation resources found that conform to profile: http://hl7.org/fhir/us/core/StructureDefinition/us-core-smokingstatus.')
    end

    it 'skips without Bodyheight resources' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept' => 'application/fhir+ndjson' })
        .to_return(status: 200, body: contents_missing_bodyheight, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, observation_input)

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('No Observation resources found that conform to profile: http://hl7.org/fhir/StructureDefinition/bodyheight.')
    end

    it 'skips without Resprate resources' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept' => 'application/fhir+ndjson' })
        .to_return(status: 200, body: contents_missing_resprate, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, observation_input)

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('No Observation resources found that conform to profile: http://hl7.org/fhir/StructureDefinition/resprate.')
    end

    it 'skips if lines_to_validate does not include enough resources to verify profile conformance' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept' => 'application/fhir+ndjson' })
        .to_return(status: 200, body: contents, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)

      result = run(runnable, observation_input.merge(lines_to_validate: 75))

      expect(result.result).to eq('skip')
      expect(result.result_message).to start_with('No Observation resources found that conform to profile')
    end

    it 'passes when the profile for every streamed resource needs to be guessed' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept' => 'application/fhir+ndjson' })
        .to_return(status: 200, body: contents_missing_profile, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, observation_input)

      expect(result.result).to eq('pass')
    end

    it 'passes with all possible resources included in the Observation Profile' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept' => 'application/fhir+ndjson' })
        .to_return(status: 200, body: contents, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, observation_input)

      expect(result.result).to eq('pass')
    end
  end

  describe '[Location resources returned conform to the US Core Location Profile] test' do
    let(:runnable) { group.tests[21] }
    let(:resources) { NDJSON::Parser.new('spec/fixtures/Location.ndjson') }
    let(:location_input) do
      input.merge({ status_output: '[{"url":"https://www.example.com","type":"Location","count":5}]' })
    end
    let(:not_location_resource) { NDJSON::Parser.new('spec/fixtures/Device.ndjson') }
    let(:not_location_contents) { '' }

    before do
      resources.each { |resource| contents << ("#{resource.to_json}\n") }
      not_location_resource.each { |resource| not_location_contents << ("#{resource.to_json}\n") }
    end

    it 'omits when no Location resources listed in status output' do
      bad_status_output = '[{"url":"https://www.example.com","type":"notLocation","count":5}]'
      result = run(runnable, location_input.merge({ status_output: bad_status_output }))

      expect(result.result).to eq('omit')
      expect(result.result_message).to eq('No Location resource file item returned by server. ' \
                                          'Location resources are optional.')
    end

    it 'fails when non Location resources are returned' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept' => 'application/fhir+ndjson' })
        .to_return(status: 200, body: not_location_contents, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, location_input)

      expect(result.result).to eq('fail')
      expect(result.result_message)
        .to eq('Resource type "Device" at line "1" does not match type defined in output "Location"')
    end

    it 'passes when the returned resources are fully conformant' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept' => 'application/fhir+ndjson' })
        .to_return(status: 200, body: contents, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, location_input)

      expect(result.result).to eq('pass')
    end
  end

  describe '[Medication resources returned conform to the US Core Medication Profile] test' do
    let(:runnable) { group.tests[22] }
    let(:resources) { NDJSON::Parser.new('spec/fixtures/Medication.ndjson') }
    let(:medication_input) do
      input.merge({ status_output: '[{"url":"https://www.example.com","type":"Medication","count":1}]' })
    end
    let(:not_medication_resource) { NDJSON::Parser.new('spec/fixtures/Device.ndjson') }
    let(:not_medication_contents) { '' }

    before do
      resources.each do |resource|
        contents << ("#{resource.to_json}\n")
        resource['code'] = nil
        contents_missing_element << ("#{resource.to_json.gsub(/[ \n]/, '')}\n")
      end
      not_medication_resource.each { |resource| not_medication_contents << ("#{resource.to_json}\n") }
    end

    it 'omits when no resources are returned' do
      bad_status_output = '[{"url":"https://www.example.com","type":"notMeds","count":5}]'
      result = run(runnable, medication_input.merge({ status_output: bad_status_output }))

      expect(result.result).to eq('omit')
      expect(result.result_message).to eq('No Medication resource file item returned by server. ' \
                                          'Medication resources are optional.')
    end

    it 'fails when the returned resources are not of the expected profile' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept' => 'application/fhir+ndjson' })
        .to_return(status: 200, body: not_medication_contents, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, medication_input)

      expect(result.result).to eq('fail')
      expect(result.result_message)
        .to eq('Resource type "Device" at line "1" does not match type defined in output "Medication"')
    end

    it 'skips when returned resources are missing a must support slice' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept' => 'application/fhir+ndjson' })
        .to_return(status: 200, body: contents_missing_element, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, medication_input)

      expect(result.result).to eq('skip')
      expect(result.result_message)
        .to eq('Could not find code in the 1 provided Medication resource(s)')
    end

    it 'passes when the returned resources are fully conformant' do
      stub_request(:get, endpoint)
        .with(headers: { 'Accept' => 'application/fhir+ndjson' })
        .to_return(status: 200, body: contents, headers: headers)

      allow_any_instance_of(runnable).to receive(:resource_is_valid?).and_return(true)
      result = run(runnable, medication_input)

      expect(result.result).to eq('pass')
    end
  end
end
