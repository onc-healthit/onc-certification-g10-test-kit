require_relative '../../lib/multi_patient_api/bulk_export_validation_tester'

class BulkExportValidationTesterClass
  include Inferno::DSL::HTTPClient
  extend Inferno::DSL::Configurable

  include BulkExportValidationTester

  def test_session_id
    nil
  end
end

RSpec.describe BulkExportValidationTesterClass do
  let(:group) { described_class.new }
  let(:url) { 'https://example1.com' }
  let(:basic_body) { 'single line response_body' }
  let(:multi_line_body) { "multi\nline\nresponse\nbody\n" }
  let(:resource) do
    FHIR.from_contents("{\"resourceType\":\"Patient\",\"id\":\"f001\",\"text\":{\"status\":\"generated\",\"div\":\"\\u003cdiv xmlns=\\\"http://www.w3.org/1999/xhtml\\\"\\u003e\\u003cp\\u003e\\u003cb\\u003eGenerated Narrative with Details\\u003c/b\\u003e\\u003c/p\\u003e\\u003cp\\u003e\\u003cb\\u003eid\\u003c/b\\u003e: f001\\u003c/p\\u003e\\u003cp\\u003e\\u003cb\\u003eidentifier\\u003c/b\\u003e: 738472983 (USUAL), ?? (USUAL)\\u003c/p\\u003e\\u003cp\\u003e\\u003cb\\u003eactive\\u003c/b\\u003e: true\\u003c/p\\u003e\\u003cp\\u003e\\u003cb\\u003ename\\u003c/b\\u003e: Pieter van de Heuvel \\u003c/p\\u003e\\u003cp\\u003e\\u003cb\\u003etelecom\\u003c/b\\u003e: ph: 0648352638(MOBILE), p.heuvel@gmail.com(HOME)\\u003c/p\\u003e\\u003cp\\u003e\\u003cb\\u003egender\\u003c/b\\u003e: male\\u003c/p\\u003e\\u003cp\\u003e\\u003cb\\u003ebirthDate\\u003c/b\\u003e: 17/11/1944\\u003c/p\\u003e\\u003cp\\u003e\\u003cb\\u003edeceased\\u003c/b\\u003e: false\\u003c/p\\u003e\\u003cp\\u003e\\u003cb\\u003eaddress\\u003c/b\\u003e: Van Egmondkade 23 Amsterdam 1024 RJ NLD (HOME)\\u003c/p\\u003e\\u003cp\\u003e\\u003cb\\u003emaritalStatus\\u003c/b\\u003e: Getrouwd \\u003cspan\\u003e(Details : {http://terminology.hl7.org/CodeSystem/v3-MaritalStatus code 'M' = 'Married', given as 'Married'})\\u003c/span\\u003e\\u003c/p\\u003e\\u003cp\\u003e\\u003cb\\u003emultipleBirth\\u003c/b\\u003e: true\\u003c/p\\u003e\\u003ch3\\u003eContacts\\u003c/h3\\u003e\\u003ctable\\u003e\\u003ctr\\u003e\\u003ctd\\u003e-\\u003c/td\\u003e\\u003ctd\\u003e\\u003cb\\u003eRelationship\\u003c/b\\u003e\\u003c/td\\u003e\\u003ctd\\u003e\\u003cb\\u003eName\\u003c/b\\u003e\\u003c/td\\u003e\\u003ctd\\u003e\\u003cb\\u003eTelecom\\u003c/b\\u003e\\u003c/td\\u003e\\u003c/tr\\u003e\\u003ctr\\u003e\\u003ctd\\u003e*\\u003c/td\\u003e\\u003ctd\\u003eEmergency Contact \\u003cspan\\u003e(Details : {http://terminology.hl7.org/CodeSystem/v2-0131 code 'C' = 'Emergency Contact)\\u003c/span\\u003e\\u003c/td\\u003e\\u003ctd\\u003eSarah Abels \\u003c/td\\u003e\\u003ctd\\u003eph: 0690383372(MOBILE)\\u003c/td\\u003e\\u003c/tr\\u003e\\u003c/table\\u003e\\u003ch3\\u003eCommunications\\u003c/h3\\u003e\\u003ctable\\u003e\\u003ctr\\u003e\\u003ctd\\u003e-\\u003c/td\\u003e\\u003ctd\\u003e\\u003cb\\u003eLanguage\\u003c/b\\u003e\\u003c/td\\u003e\\u003ctd\\u003e\\u003cb\\u003ePreferred\\u003c/b\\u003e\\u003c/td\\u003e\\u003c/tr\\u003e\\u003ctr\\u003e\\u003ctd\\u003e*\\u003c/td\\u003e\\u003ctd\\u003eNederlands \\u003cspan\\u003e(Details : {urn:ietf:bcp:47 code 'nl' = 'Dutch', given as 'Dutch'})\\u003c/span\\u003e\\u003c/td\\u003e\\u003ctd\\u003etrue\\u003c/td\\u003e\\u003c/tr\\u003e\\u003c/table\\u003e\\u003cp\\u003e\\u003cb\\u003emanagingOrganization\\u003c/b\\u003e: \\u003ca\\u003eBurgers University Medical Centre\\u003c/a\\u003e\\u003c/p\\u003e\\u003c/div\\u003e\"},\"identifier\":[{\"use\":\"usual\",\"system\":\"urn:oid:2.16.840.1.113883.2.4.6.3\",\"value\":\"738472983\"},{\"use\":\"usual\",\"system\":\"urn:oid:2.16.840.1.113883.2.4.6.3\"}],\"active\":true,\"name\":[{\"use\":\"usual\",\"family\":\"van de Heuvel\",\"given\":[\"Pieter\"],\"suffix\":[\"MSc\"]}],\"telecom\":[{\"system\":\"phone\",\"value\":\"0648352638\",\"use\":\"mobile\"},{\"system\":\"email\",\"value\":\"p.heuvel@gmail.com\",\"use\":\"home\"}],\"gender\":\"male\",\"birthDate\":\"1944-11-17\",\"deceasedBoolean\":false,\"address\":[{\"use\":\"home\",\"line\":[\"Van Egmondkade 23\"],\"city\":\"Amsterdam\",\"postalCode\":\"1024 RJ\",\"country\":\"NLD\"}],\"maritalStatus\":{\"coding\":[{\"system\":\"http://terminology.hl7.org/CodeSystem/v3-MaritalStatus\",\"code\":\"M\",\"display\":\"Married\"}],\"text\":\"Getrouwd\"},\"multipleBirthBoolean\":true,\"contact\":[{\"relationship\":[{\"coding\":[{\"system\":\"http://terminology.hl7.org/CodeSystem/v2-0131\",\"code\":\"C\"}]}],\"name\":{\"use\":\"usual\",\"family\":\"Abels\",\"given\":[\"Sarah\"]},\"telecom\":[{\"system\":\"phone\",\"value\":\"0690383372\",\"use\":\"mobile\"}]}],\"communication\":[{\"language\":{\"coding\":[{\"system\":\"urn:ietf:bcp:47\",\"code\":\"nl\",\"display\":\"Dutch\"}],\"text\":\"Nederlands\"},\"preferred\":true}],\"managingOrganization\":{\"reference\":\"Organization/f001\",\"display\":\"Burgers University Medical Centre\"}}")
  end
  let(:generic_block) { proc { |chunk| } }
  let(:streamed_chunks) { [] }
  let(:streamed_response) { [] }
  let(:process_line_block) { proc { |chunk| streamed_chunks << ("#{chunk} touched") } }
  let(:process_response_block) { proc { |response| streamed_response << response[:headers][0].value } }
  let(:client) do
    block = proc { url url }
    Inferno::DSL::HTTPClientBuilder.new.build(group, block)
  end

  describe 'stream_ndjson' do
    it 'makes a stream request using the given endpoint' do
      stub_request(:get, url.to_s)
        .to_return(status: 200, body: '', headers: {})

      group.stream_ndjson(url, {}, generic_block, generic_block)

      expect(group.response[:status]).to eq(200)
    end

    it 'applies process_header once, upon reception of a single, one-line chunk' do
      stub_request(:get, url.to_s)
        .to_return(status: 200, body: basic_body, headers: { 'Application' => 'expected' })

      group.stream_ndjson(url, {}, generic_block, process_response_block)

      expect(streamed_response).to eq(['expected'])
    end

    it 'applies process_header several times, upon reception of multiple chunks' do
    end

    it 'applies process_chunk_line to single, one-line chunk of a stream' do
      stub_request(:get, url.to_s)
        .to_return(status: 200, body: basic_body, headers: {})

      group.stream_ndjson(url, {}, process_line_block, generic_block)

      expect(streamed_chunks).to eq(["#{basic_body} touched"])
    end

    it 'applies process_chunk_line to single, multi-line chunk of a stream' do
      stub_request(:get, url.to_s)
        .to_return(status: 200, body: multi_line_body, headers: {})

      group.stream_ndjson(url, {}, process_line_block, generic_block)

      expect(streamed_chunks).to eq(["multi\n touched", "line\n touched", "response\n touched", "body\n touched"])
    end
  end
end
