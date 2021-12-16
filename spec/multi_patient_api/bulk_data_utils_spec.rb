require_relative '../../lib/multi_patient_api/bulk_data_utils.rb'

class BulkDataUtilsTestClass
  include Inferno::DSL::HTTPClient
  extend Inferno::DSL::Configurable

  include BulkDataUtils
  
  def test_session_id 
    nil 
  end 
end 

RSpec.describe BulkDataUtils do
  let(:group) { BulkDataUtilsTestClass.new }
  let(:url) { 'https://example1.com' }
  let(:basic_body) { 'single line response_body' }
  let(:multi_line_body) { "multi\nline\nresponse\nbody\n" }
  let(:resource) { FHIR.from_contents("{\"resourceType\":\"Patient\",\"id\":\"f001\",\"text\":{\"status\":\"generated\",\"div\":\"\\u003cdiv xmlns=\\\"http://www.w3.org/1999/xhtml\\\"\\u003e\\u003cp\\u003e\\u003cb\\u003eGenerated Narrative with Details\\u003c/b\\u003e\\u003c/p\\u003e\\u003cp\\u003e\\u003cb\\u003eid\\u003c/b\\u003e: f001\\u003c/p\\u003e\\u003cp\\u003e\\u003cb\\u003eidentifier\\u003c/b\\u003e: 738472983 (USUAL), ?? (USUAL)\\u003c/p\\u003e\\u003cp\\u003e\\u003cb\\u003eactive\\u003c/b\\u003e: true\\u003c/p\\u003e\\u003cp\\u003e\\u003cb\\u003ename\\u003c/b\\u003e: Pieter van de Heuvel \\u003c/p\\u003e\\u003cp\\u003e\\u003cb\\u003etelecom\\u003c/b\\u003e: ph: 0648352638(MOBILE), p.heuvel@gmail.com(HOME)\\u003c/p\\u003e\\u003cp\\u003e\\u003cb\\u003egender\\u003c/b\\u003e: male\\u003c/p\\u003e\\u003cp\\u003e\\u003cb\\u003ebirthDate\\u003c/b\\u003e: 17/11/1944\\u003c/p\\u003e\\u003cp\\u003e\\u003cb\\u003edeceased\\u003c/b\\u003e: false\\u003c/p\\u003e\\u003cp\\u003e\\u003cb\\u003eaddress\\u003c/b\\u003e: Van Egmondkade 23 Amsterdam 1024 RJ NLD (HOME)\\u003c/p\\u003e\\u003cp\\u003e\\u003cb\\u003emaritalStatus\\u003c/b\\u003e: Getrouwd \\u003cspan\\u003e(Details : {http://terminology.hl7.org/CodeSystem/v3-MaritalStatus code 'M' = 'Married', given as 'Married'})\\u003c/span\\u003e\\u003c/p\\u003e\\u003cp\\u003e\\u003cb\\u003emultipleBirth\\u003c/b\\u003e: true\\u003c/p\\u003e\\u003ch3\\u003eContacts\\u003c/h3\\u003e\\u003ctable\\u003e\\u003ctr\\u003e\\u003ctd\\u003e-\\u003c/td\\u003e\\u003ctd\\u003e\\u003cb\\u003eRelationship\\u003c/b\\u003e\\u003c/td\\u003e\\u003ctd\\u003e\\u003cb\\u003eName\\u003c/b\\u003e\\u003c/td\\u003e\\u003ctd\\u003e\\u003cb\\u003eTelecom\\u003c/b\\u003e\\u003c/td\\u003e\\u003c/tr\\u003e\\u003ctr\\u003e\\u003ctd\\u003e*\\u003c/td\\u003e\\u003ctd\\u003eEmergency Contact \\u003cspan\\u003e(Details : {http://terminology.hl7.org/CodeSystem/v2-0131 code 'C' = 'Emergency Contact)\\u003c/span\\u003e\\u003c/td\\u003e\\u003ctd\\u003eSarah Abels \\u003c/td\\u003e\\u003ctd\\u003eph: 0690383372(MOBILE)\\u003c/td\\u003e\\u003c/tr\\u003e\\u003c/table\\u003e\\u003ch3\\u003eCommunications\\u003c/h3\\u003e\\u003ctable\\u003e\\u003ctr\\u003e\\u003ctd\\u003e-\\u003c/td\\u003e\\u003ctd\\u003e\\u003cb\\u003eLanguage\\u003c/b\\u003e\\u003c/td\\u003e\\u003ctd\\u003e\\u003cb\\u003ePreferred\\u003c/b\\u003e\\u003c/td\\u003e\\u003c/tr\\u003e\\u003ctr\\u003e\\u003ctd\\u003e*\\u003c/td\\u003e\\u003ctd\\u003eNederlands \\u003cspan\\u003e(Details : {urn:ietf:bcp:47 code 'nl' = 'Dutch', given as 'Dutch'})\\u003c/span\\u003e\\u003c/td\\u003e\\u003ctd\\u003etrue\\u003c/td\\u003e\\u003c/tr\\u003e\\u003c/table\\u003e\\u003cp\\u003e\\u003cb\\u003emanagingOrganization\\u003c/b\\u003e: \\u003ca\\u003eBurgers University Medical Centre\\u003c/a\\u003e\\u003c/p\\u003e\\u003c/div\\u003e\"},\"identifier\":[{\"use\":\"usual\",\"system\":\"urn:oid:2.16.840.1.113883.2.4.6.3\",\"value\":\"738472983\"},{\"use\":\"usual\",\"system\":\"urn:oid:2.16.840.1.113883.2.4.6.3\"}],\"active\":true,\"name\":[{\"use\":\"usual\",\"family\":\"van de Heuvel\",\"given\":[\"Pieter\"],\"suffix\":[\"MSc\"]}],\"telecom\":[{\"system\":\"phone\",\"value\":\"0648352638\",\"use\":\"mobile\"},{\"system\":\"email\",\"value\":\"p.heuvel@gmail.com\",\"use\":\"home\"}],\"gender\":\"male\",\"birthDate\":\"1944-11-17\",\"deceasedBoolean\":false,\"address\":[{\"use\":\"home\",\"line\":[\"Van Egmondkade 23\"],\"city\":\"Amsterdam\",\"postalCode\":\"1024 RJ\",\"country\":\"NLD\"}],\"maritalStatus\":{\"coding\":[{\"system\":\"http://terminology.hl7.org/CodeSystem/v3-MaritalStatus\",\"code\":\"M\",\"display\":\"Married\"}],\"text\":\"Getrouwd\"},\"multipleBirthBoolean\":true,\"contact\":[{\"relationship\":[{\"coding\":[{\"system\":\"http://terminology.hl7.org/CodeSystem/v2-0131\",\"code\":\"C\"}]}],\"name\":{\"use\":\"usual\",\"family\":\"Abels\",\"given\":[\"Sarah\"]},\"telecom\":[{\"system\":\"phone\",\"value\":\"0690383372\",\"use\":\"mobile\"}]}],\"communication\":[{\"language\":{\"coding\":[{\"system\":\"urn:ietf:bcp:47\",\"code\":\"nl\",\"display\":\"Dutch\"}],\"text\":\"Nederlands\"},\"preferred\":true}],\"managingOrganization\":{\"reference\":\"Organization/f001\",\"display\":\"Burgers University Medical Centre\"}}") }
  let(:generic_block) { Proc.new { |chunk| } }
  let(:streamed_chunks) { [] }
  let(:streamed_response) { [] }
  let(:process_line_block) { Proc.new { |chunk| streamed_chunks << chunk + ' touched' } }
  let(:process_response_block) { Proc.new { |response| streamed_response << response[:headers][0].value }}
  let(:client) do
    block = proc { url url }
    Inferno::DSL::HTTPClientBuilder.new.build(group, block)
  end

  describe 'resolve_element_from_path' do
    it 'returns false if given nil as path' do
      result = group.resolve_element_from_path(resource, nil)
      expect(result).to eq(false)
    end

    it 'returns true if given an empty path and a non-empty resource' do
      result = group.resolve_element_from_path(resource, "")
      expect(result).to eq(true)
    end

    it 'returns false if given a malformed path' do
      result = group.resolve_element_from_path(resource, 0)
      expect(result).to eq(false)
    end 

    it 'returns false if given a completely invalid path' do
      result = group.resolve_element_from_path(resource, "not_a_valid_path")
      expect(result).to eq(false)
    end 

    it 'returns false if given a path with an invalid step' do
      result = group.resolve_element_from_path(resource, "identifier.not_a_valid_step")
      expect(result).to eq(false)
    end

    it 'returns true if given an otherwise valid path with an empty step' do
      result = group.resolve_element_from_path(resource, "identifier..")
      expect(result).to eq(true)
    end

    context 'given a valid path' do 
      context 'returns false' do
        it 'if path expects an attribute that is not in the resource' do
          result = group.resolve_element_from_path(resource, "not_a_valid_resource")
          expect(result).to eq(false)
        end
        it 'if path first expects an array element that is empty in the resource' do
          result = group.resolve_element_from_path(resource, "extension.url")
          expect(result).to eq(false)
        end
        it 'if path expects a nested array element that is empty in the resource' do
          result = group.resolve_element_from_path(resource, "managingOrganization.extension.url")
          expect(result).to eq(false)
        end
        it 'if path expects a nested FHIR element attribute that is empty in the resource' do
          result = group.resolve_element_from_path(resource, "managingOrganization.identifier.type")
          expect(result).to eq(false)
        end
        it 'if the resource contains the given path, but the block returns false' do
          result = group.resolve_element_from_path(resource, "contact.name.given") do |name|
            !(name == ['Sarah'])
          end 
          expect(result).to eq(false)
        end
        it 'returns true if the resource contains multiple elements at the given path and at least one returns true for the block' do
          
        end
      end
      context 'returns true' do
        it 'if path expects an attribute that is in the resource' do
          result = group.resolve_element_from_path(resource, "gender")
          expect(result).to eq(true)
        end
        it 'returns true if the resource contains the given path and the block returns true' do
        
        end
        it 'returns true if the resource contains multiple elements at the given path and at least one returns true for the block' do
          
        end
        it 'returns true if the resource contains the given path and no block is given' do
          
        end
        
      end
    end 
  end

  describe 'find_slice_by_values' do
    
  end

  describe 'find_slice' do
    
  end

  describe 'process_must_support' do
    
  end

  describe 'pull_invalid_bindings' do
    
  end

  describe 'validate_bindings' do 

  end 

  describe 'process_profile_definitions' do
    
  end

  describe 'stream_ndjson' do

    it 'makes a stream request using the given endpoint' do 
      stub_request(:get, "#{url}")
        .to_return(status: 200, body: "", headers: {})

      group.stream_ndjson(url, {}, generic_block, generic_block)

      expect(group.response[:status]).to eq(200)
    end 

    it 'applies process_header once, upon reception of a single, one-line chunk' do
      stub_request(:get, "#{url}")
        .to_return(status: 200, body: basic_body, headers: {'Application' => 'expected'})

      group.stream_ndjson(url, {}, generic_block, process_response_block)

      expect(streamed_response).to eq(['expected'])
    end

    it 'applies process_header several times, upon reception of multiple chunks' do

    end

    it 'applies process_chunk_line to single, one-line chunk of a stream' do
      stub_request(:get, "#{url}")
        .to_return(status: 200, body: basic_body, headers: {})

      group.stream_ndjson(url, {}, process_line_block, generic_block)

      expect(streamed_chunks).to eq([basic_body + ' touched'])
    end

    it 'applies process_chunk_line to single, multi-line chunk of a stream' do
      stub_request(:get, "#{url}")
        .to_return(status: 200, body: multi_line_body, headers: {})

      group.stream_ndjson(url, {}, process_line_block, generic_block)

      expect(streamed_chunks).to eq(["multi\n touched", "line\n touched", "response\n touched", "body\n touched"])
    end 
    
    # TODO: Unsure how to mimic streamed_chunks data files
    it 'applies process_chunk_line to multiple, one-line chunks of a stream' do
      
    end 

    it 'applies process_chunk_line to multiple, multi-line chunks of a stream' do
      
    end 
  end 

  describe 'check_file_request' do
    

  end

  describe 'output_conforms_to_profile?' do

    #bulk_status_output = "[{\"type\":\"Patient\",\"count\":25,\"url\":\"https://bulk-data.smarthealthit.org/eyJpZCI6IjE1NGExYmZhMGQ2ZjRiOTI5ZDA0ZWU5ZWEwOWEzODhmIiwib2Zmc2V0IjowLCJsaW1pdCI6MjUsInNlY3VyZSI6dHJ1ZX0/fhir/bulkfiles/1.Patient.ndjson\"}]" 

    # it 'raises an exception when bulk_status_output is not defined' do
    #   expect {
    #     group.output_conforms_to_profile?('Patient')
    #   }.to raise_error(Inferno::Exceptions::AssertionException)
    # end 

    # it 'raises an exception when bulk_status_output is not valid JSON' do
    #   group.define_singleton_method(:bulk_status_output) { output }
    #   binding.pry
    #   expect {
    #     group.output_conforms_to_profile?('Patient')
    #   }.to raise_error(Inferno::Exceptions::AssertionException)
    # end 
    # bulk_status_output not extant
    # bulk_status_output extant 
    
  end

end 