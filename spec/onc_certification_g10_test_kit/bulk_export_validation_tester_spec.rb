require_relative '../../lib/onc_certification_g10_test_kit/bulk_export_validation_tester'
require 'ndjson'

class BulkExportValidationTesterClass < Inferno::Test
  include ONCCertificationG10TestKit::BulkExportValidationTester
  attr_accessor :status_output, :requires_access_token, :bearer_token, :resource_type, :lines_to_validate, :scratch,
                :bulk_device_types_in_group

  def test_session_id
    nil
  end
end

RSpec.describe ONCCertificationG10TestKit::BulkExportValidationTester do
  let(:url) { 'https://example1.com' }
  let(:status_output) { "[{\"url\":\"#{url}\",\"type\":\"Patient\",\"count\":2}]" }
  let(:requires_access_token) { 'true' }
  let(:bearer_token) { 'bearer_token' }
  let(:lines_to_validate) { 10 }
  let(:resource_type) { 'Patient' }
  let(:tester) { BulkExportValidationTesterClass.new }
  let(:headers) { { 'content-type' => 'application/fhir+ndjson' } }
  let(:patient_contents) { String.new }
  let(:care_plan_contents) { String.new }
  let(:encounter_contents) { String.new }
  let(:device_contents) { String.new }
  let(:location_contents) { String.new }
  let(:medication_contents) { String.new }
  let(:patient_contents_one_id) { String.new }
  let(:one_id) { 'one_id' }
  let(:patient_ids_seen) { ['e91975f5-9445-c11f-cabf-c3c6dae161f2', 'd831ec91-c7a3-4a61-9312-7ff0c4a32134'] }
  let(:device_resource) { FHIR.from_contents(device_contents.lines[0]) }

  before do
    tester.status_output = status_output
    tester.requires_access_token = requires_access_token
    tester.bearer_token = bearer_token
    tester.lines_to_validate = lines_to_validate
    tester.resource_type = resource_type
    tester.scratch = {}
    tester.bulk_device_types_in_group = '72506001'
    NDJSON::Parser.new('spec/fixtures/Patient.ndjson').each do |resource|
      patient_contents << ("#{resource.to_json}\n")
      resource['id'] = one_id
      patient_contents_one_id << ("#{resource.to_json.gsub(/[ \n]/, '')}\n")
    end
    NDJSON::Parser.new('spec/fixtures/CarePlan.ndjson').each do |resource|
      care_plan_contents << ("#{resource.to_json}\n")
    end
    NDJSON::Parser.new('spec/fixtures/Encounter.ndjson').each do |resource|
      encounter_contents << ("#{resource.to_json}\n")
    end
    NDJSON::Parser.new('spec/fixtures/Device.ndjson').each do |resource|
      device_contents << ("#{resource.to_json}\n")
    end
    NDJSON::Parser.new('spec/fixtures/Location.ndjson').each do |resource|
      location_contents << ("#{resource.to_json}\n")
    end
    NDJSON::Parser.new('spec/fixtures/Medication.ndjson').each do |resource|
      medication_contents << ("#{resource.to_json}\n")
    end
  end

  describe '#perform_bulk_export_validation' do
    it 'skips when status_output is not provided' do
      tester.status_output = nil

      expect { tester.perform_bulk_export_validation }
        .to raise_exception(Inferno::Exceptions::SkipException)
        .with_message('Could not verify this functionality when Bulk Status Output is not provided')
    end

    it 'skips when requires_access_token is true and bearer_token is not provided' do
      tester.bearer_token = nil

      expect { tester.perform_bulk_export_validation }
        .to raise_exception(Inferno::Exceptions::SkipException)
        .with_message('Could not verify this functionality when Bearer Token is required and not provided')
    end

    it 'skips when no Patient resource file item returned by server' do
      tester.status_output = "[{\"url\":\"#{url}\",\"type\":\"Location\",\"count\":2}]"

      expect { tester.perform_bulk_export_validation }
        .to raise_exception(Inferno::Exceptions::SkipException)
        .with_message('No Patient resource file item returned by server.')
    end

    it 'makes a request without bearer token header when requires_access_token is not provided' do
      tester.requires_access_token = nil

      bearer_req = stub_request(:get, url)
        .with(headers: { 'authorization' => "Bearer #{bearer_token}" })
        .to_return(status: 200, headers: headers, body: patient_contents)
      non_bearer_req = stub_request(:get, url)
        .to_return(status: 200, headers: headers, body: patient_contents)

      allow(tester).to receive(:resource_is_valid?).and_return(true)

      expect { tester.perform_bulk_export_validation }
        .to raise_exception(Inferno::Exceptions::PassException)

      expect(bearer_req).to_not have_been_made
      expect(non_bearer_req).to have_been_made.once
    end

    it 'makes a request without bearer token header when requires_access_token is false' do
      tester.requires_access_token = 'false'

      bearer_req = stub_request(:get, url)
        .with(headers: { 'authorization' => "Bearer #{bearer_token}" })
        .to_return(status: 200, headers: headers, body: patient_contents)
      non_bearer_req = stub_request(:get, url)
        .to_return(status: 200, headers: headers, body: patient_contents)

      allow(tester).to receive(:resource_is_valid?).and_return(true)

      expect { tester.perform_bulk_export_validation }
        .to raise_exception(Inferno::Exceptions::PassException)

      expect(bearer_req).to_not have_been_made
      expect(non_bearer_req).to have_been_made.once
    end

    it 'passes when lines_to_validate is unset' do
      tester.lines_to_validate = nil

      stub_request(:get, url)
        .to_return(status: 200, headers: headers, body: patient_contents)

      allow(tester).to receive(:resource_is_valid?).and_return(true)

      expect { tester.perform_bulk_export_validation }
        .to raise_exception(Inferno::Exceptions::PassException)
        .with_message('Successfully validated 2 Patient resource(s).')
    end

    it 'passes when Patient resource items returend prove conformance to profile' do
      stub_request(:get, url)
        .to_return(status: 200, headers: headers, body: patient_contents)

      allow(tester).to receive(:resource_is_valid?).and_return(true)

      expect { tester.perform_bulk_export_validation }
        .to raise_exception(Inferno::Exceptions::PassException)
        .with_message('Successfully validated 2 Patient resource(s).')
    end
  end

  describe '#check_file_request' do
    context 'with lines_to_validate = 1' do
      before { tester.lines_to_validate = 1 }

      it 'validates 1 of the given non-Patient resources' do
        tester.resource_type = 'CarePlan'

        stub_request(:get, url)
          .to_return(status: 200, headers: headers, body: care_plan_contents)

        allow(tester).to receive(:resource_is_valid?).and_return(true)
        result = tester.check_file_request(url)

        expect(result).to eq(1)
      end

      it 'respects MIN_RESOURCE_COUNT and validates the two given Patient resources' do
        stub_request(:get, url)
          .to_return(status: 200, headers: headers, body: patient_contents)

        allow(tester).to receive(:resource_is_valid?).and_return(true)
        result = tester.check_file_request(url)

        expect(result).to eq(2)
        expect(tester.patient_ids_seen).to eq(patient_ids_seen)
      end

      context 'with all returned Patient resources having same id' do
        it 'respects MIN_RESOURCE_COUNT and validates the two given Patient resources
             but adds only first id to patient_ids_seen)' do
          stub_request(:get, url)
            .to_return(status: 200, headers: headers, body: patient_contents_one_id)

          allow(tester).to receive(:resource_is_valid?).and_return(true)
          result = tester.check_file_request(url)

          expect(result).to eq(2)
          expect(tester.patient_ids_seen).to eq([one_id])
        end
      end
    end

    context 'with lines_to_validate = 100' do
      before { tester.lines_to_validate = 100 }

      context 'when less than 100 resources are returned' do
        it 'validates all returned resources' do
          tester.resource_type = 'CarePlan'

          stub_request(:get, url)
            .to_return(status: 200, headers: headers, body: care_plan_contents)

          allow(tester).to receive(:resource_is_valid?).and_return(true)
          result = tester.check_file_request(url)

          expect(result).to eq(26)
        end
      end

      context 'with more than 100 resources' do
        it 'validates the first 100 returned resources' do
          tester.resource_type = 'Encounter'

          stub_request(:get, url)
            .to_return(status: 200, headers: headers, body: encounter_contents)

          allow(tester).to receive(:resource_is_valid?).and_return(true)
          result = tester.check_file_request(url)

          expect(result).to eq(100)
        end
      end
    end

    context 'with lines_to_validate unset' do
      it 'validates all resources' do
        tester.lines_to_validate = nil
        tester.resource_type = 'Encounter'

        stub_request(:get, url)
          .to_return(status: 200, headers: headers, body: encounter_contents)

        allow(tester).to receive(:resource_is_valid?).and_return(true)
        result = tester.check_file_request(url)

        expect(result).to eq(189)
      end
    end

    it 'skips when returned contents is not a FHIR resource' do
      stub_request(:get, url)
        .to_return(status: 200, headers: headers, body: '')

      expect { tester.check_file_request(url) }
        .to raise_exception(Inferno::Exceptions::SkipException)
        .with_message('Server response at line "1" is not a processable FHIR resource.')
    end

    it 'fails when returned contents is not of the expected resource type' do
      stub_request(:get, url)
        .to_return(status: 200, headers: headers, body: encounter_contents)

      expect { tester.check_file_request(url) }
        .to raise_exception(Inferno::Exceptions::AssertionException)
        .with_message('Resource type "Encounter" at line "1" does not match type defined in output "Patient"')
    end

    it 'fails when returned contents is not valid for the expected resource type' do
      stub_request(:get, url)
        .to_return(status: 200, headers: headers, body: patient_contents)

      allow(tester).to receive(:resource_is_valid?).and_return(false)
      expect { tester.check_file_request(url) }
        .to raise_exception(Inferno::Exceptions::AssertionException)
        .with_message('Resource at line "1" does not conform to profile "http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient".')
    end

    context 'with improper headers' do
      it 'skips if given no headers' do
        stub_request(:get, url)
          .to_return(status: 200, body: patient_contents)

        allow(tester).to receive(:resource_is_valid?).and_return(true)
        expect { tester.check_file_request(url) }
          .to raise_exception(Inferno::Exceptions::SkipException)
          .with_message("Content type must have 'application/fhir+ndjson' but found ''")
      end

      it "skips if given headers that don't contain 'content-type'" do
        stub_request(:get, url)
          .to_return(status: 200, headers: { 'not-content-type' => '' }, body: patient_contents)

        allow(tester).to receive(:resource_is_valid?).and_return(true)
        expect { tester.check_file_request(url) }
          .to raise_exception(Inferno::Exceptions::SkipException)
          .with_message("Content type must have 'application/fhir+ndjson' but found ''")
      end

      it "skips if 'content-type' header value is nil" do
        stub_request(:get, url)
          .to_return(status: 200, headers: { 'content-type' => nil }, body: patient_contents)

        allow(tester).to receive(:resource_is_valid?).and_return(true)
        expect { tester.check_file_request(url) }
          .to raise_exception(Inferno::Exceptions::SkipException)
          .with_message("Content type must have 'application/fhir+ndjson' but found ''")
      end

      it "skips if 'content-type' header value is not application/fhir+ndjson" do
        stub_request(:get, url)
          .to_return(status: 200, headers: { 'content-type' => 'wrong_type' }, body: patient_contents)

        allow(tester).to receive(:resource_is_valid?).and_return(true)
        expect { tester.check_file_request(url) }
          .to raise_exception(Inferno::Exceptions::SkipException)
          .with_message("Content type must have 'application/fhir+ndjson' but found 'wrong_type'")
      end
    end

    context 'with lines_to_validate_unset, proper resources and headers returned' do
      it 'returns the expected number of Location resources' do
        tester.lines_to_validate = nil
        tester.resource_type = 'Location'

        stub_request(:get, url)
          .to_return(status: 200, headers: headers, body: location_contents)

        allow(tester).to receive(:resource_is_valid?).and_return(true)
        result = tester.check_file_request(url)

        expect(result).to eq(5)
      end

      it 'returns the expected number of Medication resources' do
        tester.lines_to_validate = nil
        tester.resource_type = 'Medication'

        stub_request(:get, url)
          .to_return(status: 200, headers: headers, body: medication_contents)

        allow(tester).to receive(:resource_is_valid?).and_return(true)
        result = tester.check_file_request(url)

        expect(result).to eq(1)
      end
    end
  end

  describe '#determine_profile' do
    it 'returns nil if given a Device resource that is not predefined' do
      tester.bulk_device_types_in_group = 'not_it'

      result = tester.determine_profile(device_resource)
      expect(result).to be_nil
    end

    it 'returns the vice profile if given a Device resource that is predefined' do
      result = tester.determine_profile(device_resource)
      expect(result).to eq('http://hl7.org/fhir/us/core/StructureDefinition/us-core-implantable-device')
    end

    it "skips if given resource's type is not defined" do
      dummy_resource = 'dummy resource'
      dummy_resource.define_singleton_method(:resourceType) { nil }

      expect { tester.determine_profile(dummy_resource) }
        .to raise_exception(Inferno::Exceptions::SkipException)
        .with_message('Could not determine profile of "" resource.')
    end

    it "returns AllergyIntolerance's profile when given an AllergyIntolerance resource" do
      result = tester.determine_profile(FHIR::AllergyIntolerance.new)
      expect(result).to eq('http://hl7.org/fhir/us/core/StructureDefinition/us-core-allergyintolerance')
    end

    it "returns Location's profile when given a Location resource" do
      result = tester.determine_profile(FHIR::Location.new)
      expect(result).to eq('http://hl7.org/fhir/StructureDefinition/Location')
    end

    it "returns Medications's profile when given a Medication resource" do
      result = tester.determine_profile(FHIR::Medication.new)
      expect(result).to eq('http://hl7.org/fhir/us/core/StructureDefinition/us-core-medication')
    end

    context 'with DiagnosticReport resource' do
      it 'returns lab profile if resource has lab criterion specified' do
        coding = FHIR::Coding.new({ code: 'LAB', system: 'http://terminology.hl7.org/CodeSystem/v2-0074' })
        category = FHIR::CodeableConcept.new({ coding: [coding] })
        diagnostic_report = FHIR::DiagnosticReport.new({ category: [category] })

        result = tester.determine_profile(diagnostic_report)
        expect(result).to eq('http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-lab')
      end

      it 'returns note profile if lab criterion unspecified' do
        result = tester.determine_profile(FHIR::DiagnosticReport.new)
        expect(result).to eq('http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-note')
      end
    end

    context 'with Observation resource' do
      let(:observation) do
        coding = FHIR::Coding.new({ code: '72166-2' })
        code = FHIR::CodeableConcept.new({ coding: [coding] })
        FHIR::Observation.new({ code: code })
      end

      it 'returns the SmokingStatus profile if resource has SmokingStatus criterion specified' do
        result = tester.determine_profile(observation)
        expect(result).to eq('http://hl7.org/fhir/us/core/StructureDefinition/us-core-smokingstatus')
      end

      it 'returns the ObservationLab profile if resource has ObservationLab criterion specified' do
        coding = FHIR::Coding.new({ code: 'laboratory',
                                    system: 'http://terminology.hl7.org/CodeSystem/observation-category' })
        category = FHIR::CodeableConcept.new({ coding: [coding] })
        observation = FHIR::Observation.new({ category: [category] })

        result = tester.determine_profile(observation)
        expect(result).to eq('http://hl7.org/fhir/us/core/StructureDefinition/us-core-observation-lab')
      end

      it 'returns the PediatricBmiForAge profile if resource has PediatricBmiForAge criterion specified' do
        observation.code.coding[0].code = '59576-9'

        result = tester.determine_profile(observation)
        expect(result).to eq('http://hl7.org/fhir/us/core/StructureDefinition/pediatric-bmi-for-age')
      end

      it 'returns the PediatricWeightForHeight profile if resource has PediatricWeightForHeight criterion specified' do
        observation.code.coding[0].code = '77606-2'

        result = tester.determine_profile(observation)
        expect(result).to eq('http://hl7.org/fhir/us/core/StructureDefinition/pediatric-weight-for-height')
      end

      it 'returns the PulseOximetry profile if resource has PulseOximetry criterion specified' do
        observation.code.coding[0].code = '59408-5'

        result = tester.determine_profile(observation)
        expect(result).to eq('http://hl7.org/fhir/us/core/StructureDefinition/us-core-pulse-oximetry')
      end

      it 'returns the HeadCircumference profile if resource has HeadCircumference criterion specified' do
        observation.code.coding[0].code = '8289-1'

        result = tester.determine_profile(observation)
        expect(result).to eq('http://hl7.org/fhir/us/core/StructureDefinition/head-occipital-frontal-circumference-percentile')
      end

      it 'returns the Bp profile if resource has Bp criterion specified' do
        observation.code.coding[0].code = '85354-9'

        result = tester.determine_profile(observation)
        expect(result).to eq('http://hl7.org/fhir/StructureDefinition/bp')
      end

      it 'returns the Bodyheight profile if resource has Bodyheight criterion specified' do
        observation.code.coding[0].code = '8302-2'

        result = tester.determine_profile(observation)
        expect(result).to eq('http://hl7.org/fhir/StructureDefinition/bodyheight')
      end

      it 'returns the Bodytemp profile if resource has Bodytemp criterion specified' do
        observation.code.coding[0].code = '8310-5'

        result = tester.determine_profile(observation)
        expect(result).to eq('http://hl7.org/fhir/StructureDefinition/bodytemp')
      end

      it 'returns the Bodyweight profile if resource has Bodyweight criterion specified' do
        observation.code.coding[0].code = '29463-7'

        result = tester.determine_profile(observation)
        expect(result).to eq('http://hl7.org/fhir/StructureDefinition/bodyweight')
      end

      it 'returns the Heartrate profile if resource has Heartrate criterion specified' do
        observation.code.coding[0].code = '8867-4'

        result = tester.determine_profile(observation)
        expect(result).to eq('http://hl7.org/fhir/StructureDefinition/heartrate')
      end

      it 'returns the Resprate profile if resource has Resprate criterion specified' do
        observation.code.coding[0].code = '9279-1'

        result = tester.determine_profile(observation)
        expect(result).to eq('http://hl7.org/fhir/StructureDefinition/resprate')
      end

      it 'returns nil when given none of the possible sets of profile criterion' do
        observation.code.coding[0].code = 'bad_code'

        result = tester.determine_profile(observation)
        expect(result).to be_nil
      end
    end
  end

  describe '#predefined_device_type' do
    it 'returns true if bulk_device_types_in_group is unset' do
      tester.bulk_device_types_in_group = nil

      result = tester.predefined_device_type?(device_resource)
      expect(result).to be(true)
    end

    context 'with bulk_device_types_in_group' do
      it 'returns false if there is no code in the given resource' do
        device_resource.type.coding[0].code = nil

        result = tester.predefined_device_type?(device_resource)
        expect(result).to be(false)
      end

      it 'returns false if no code in the given resource matches any code in bulk_device_types_in_group' do
        device_resource.type.coding[0].code = 'not_it'

        result = tester.predefined_device_type?(device_resource)
        expect(result).to be(false)
      end

      it 'returns true if a code in the given resource matches a code in bulk_device_types_in_group' do
        result = tester.predefined_device_type?(device_resource)
        expect(result).to be(true)
      end
    end
  end

  describe '#stream_ndjson' do
    let(:basic_body) { 'single line response_body' }
    let(:multi_line_body) { "multi\nline\nresponse\nbody\n" }
    let(:generic_block) { proc { |chunk| } }
    let(:streamed_chunks) { [] }
    let(:streamed_headers) { [] }
    let(:process_line_block) { proc { |chunk| streamed_chunks << ("#{chunk} touched") } }
    let(:process_headers_block) { proc { |response| streamed_headers << response[:headers][0].value } }

    it 'makes a stream request using the given endpoint' do
      stub_request(:get, url).to_return(status: 200)

      tester.stream_ndjson(url, {}, generic_block, generic_block)

      expect(tester.response[:status]).to eq(200)
    end

    it 'applies process_header once, upon reception of a single, one-line chunk' do
      stub_request(:get, url)
        .to_return(status: 200, body: basic_body, headers: headers)

      tester.stream_ndjson(url, {}, generic_block, process_headers_block)

      expect(streamed_headers).to eq(headers.values)
    end

    it 'applies process_chunk_line to single, one-line chunk of a stream' do
      stub_request(:get, url)
        .to_return(status: 200, body: basic_body)

      tester.stream_ndjson(url, {}, process_line_block, generic_block)

      expect(streamed_chunks).to eq(["#{basic_body} touched"])
    end

    it 'applies process_chunk_line to single, multi-line chunk of a stream' do
      stub_request(:get, url.to_s)
        .to_return(status: 200, body: multi_line_body)

      tester.stream_ndjson(url, {}, process_line_block, generic_block)

      expect(streamed_chunks).to eq(["multi\n touched", "line\n touched", "response\n touched", "body\n touched"])
    end


    context '301 redirect' do
      let(:headers_with_authorization) {
        {
          accept: 'application/fhir+ndjson',
          authorization: "Bearer #{bearer_token}"
        }
      }
      let(:headers_without_authorization) {
        {
          accept: 'application/fhir+ndjson'
        }
      }
      let(:redirect_url) { 'http://example.com/redirect' }

      it 'accepts 301 redirect' do
        stub_request(:get, url.to_s)
          .with(headers: headers_with_authorization)
          .to_return(status: 301, headers: { 'location' => redirect_url })
        stub_request(:get, redirect_url)
          .with(headers: headers_without_authorization)
          .to_return(status: 200)

        tester.stream_ndjson(url, headers_with_authorization, process_line_block, generic_block)

        expect(tester.response[:status]).to eq(200)
      end
    end
  end
end
