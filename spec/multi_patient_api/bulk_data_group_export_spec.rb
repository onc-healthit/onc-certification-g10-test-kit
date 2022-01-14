require_relative '../../lib/multi_patient_api/bulk_data_group_export.rb'
require_relative '../../lib/multi_patient_api/bulk_data_utils.rb'

RSpec.describe MultiPatientAPI::BulkDataGroupExport do

  let(:group) { Inferno::Repositories::TestGroups.new.find('bulk_data_group_export') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_group_id: 'bulk_data_group_export') }
  let(:bulk_server_url) { 'https://example.com/fhir' }
  let(:bearer_token) { 'some_bearer_token_alphanumeric' }
  let(:group_id) { '1219' }
  let(:polling_url) { 'https://redirect.com' }
  let(:base_input) do
    {
      bulk_server_url: bulk_server_url,
      bearer_token: bearer_token,
      group_id: group_id
    }
  end
  let(:capability_statement) do
    "{\"resourceType\":\"CapabilityStatement\",\"status\":\"active\",\"date\":\"2021-11-18T19:22:48+00:00\",\"publisher\":\"Boston Children's Hospital\",\"kind\":\"instance\",\"instantiates\":[\"http://hl7.org/fhir/uv/bulkdata/CapabilityStatement/bulk-data\"],\"software\":{\"name\":\"SMART Sample Bulk Data Server\",\"version\":\"2.1.1\"},\"implementation\":{\"description\":\"SMART Sample Bulk Data Server\"},\"fhirVersion\":\"4.0.1\",\"acceptUnknown\":\"extensions\",\"format\":[\"json\"],\"rest\":[{\"mode\":\"server\",\"security\":{\"extension\":[{\"url\":\"http://fhir-registry.smarthealthit.org/StructureDefinition/oauth-uris\",\"extension\":[{\"url\":\"token\",\"valueUri\":\"https://inferno.healthit.gov/bulk-data-server/auth/token\"},{\"url\":\"register\",\"valueUri\":\"https://inferno.healthit.gov/bulk-data-server/auth/register\"}]}],\"service\":[{\"coding\":[{\"system\":\"http://hl7.org/fhir/restful-security-service\",\"code\":\"SMART-on-FHIR\",\"display\":\"SMART-on-FHIR\"}],\"text\":\"OAuth2 using SMART-on-FHIR profile (see http://docs.smarthealthit.org)\"}]},\"resource\":[{\"type\":\"Patient\",\"operation\":[{\"extension\":[{\"url\":\"http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation\",\"valueCode\":\"SHOULD\"}],\"name\":\"patient-export\",\"definition\":\"http://hl7.org/fhir/uv/bulkdata/OperationDefinition/patient-export\"}]},{\"type\":\"Group\",\"operation\":[{\"extension\":[{\"url\":\"http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation\",\"valueCode\":\"SHOULD\"}],\"name\":\"group-export\",\"definition\":\"http://hl7.org/fhir/uv/bulkdata/OperationDefinition/group-export\"}]},{\"type\":\"OperationDefinition\",\"profile\":{\"reference\":\"http://hl7.org/fhir/Profile/OperationDefinition\"},\"interaction\":[{\"code\":\"read\"}],\"searchParam\":[]}],\"operation\":[{\"name\":\"get-resource-counts\",\"definition\":\"OperationDefinition/-s-get-resource-counts\"},{\"extension\":[{\"url\":\"http://hl7.org/fhir/StructureDefinition/capabilitystatement-expectation\",\"valueCode\":\"SHOULD\"}],\"name\":\"export\",\"definition\":\"http://hl7.org/fhir/uv/bulkdata/OperationDefinition/export\"}]}]}"
  end
  let(:status_response) do
    '{"transactionTime":"2021-11-30T13:40:29.828Z","request":"https://inferno.healthit.gov/bulk-data-server/eyJlcnIiOiIiLCJwYWdlIjoxMDAwMCwiZHVyIjoxMCwidGx0Ijo2MCwibSI6MSwic3R1Ijo0LCJkZWwiOjB9/fhir/Group/1f76e2b7-a222-4765-9097-a71b86e90d07/$export","requiresAccessToken":true,"output":[],"deleted":[],"error":[]}'
  end
  let(:status_output) do
    '{"output":[{"type":"AllergyIntolerance","count":14,"url":"https://bulk-data.smarthealthit.org/eyJpZCI6ImQzOWY5MTgxN2JjYTkwZGI2YTgyYTZiZDhkODUwNzQ1Iiwib2Zmc2V0IjowLCJsaW1pdCI6MTQsInNlY3VyZSI6dHJ1ZX0/fhir/bulkfiles/1.AllergyIntolerance.ndjson"},{"type":"CarePlan","count":69,"url":"https://bulk-data.smarthealthit.org/eyJpZCI6ImQzOWY5MTgxN2JjYTkwZGI2YTgyYTZiZDhkODUwNzQ1Iiwib2Zmc2V0IjowLCJsaW1pdCI6NjksInNlY3VyZSI6dHJ1ZX0/fhir/bulkfiles/1.CarePlan.ndjson"}]}'
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
    Inferno::TestRunner.new(test_session: test_session, test_run: test_run).run(runnable)
  end

  # TODO: Write TLS unit tests after TLS tester class created.
  describe 'endpoint TLS tests' do

  end

  describe '[Bulk Data Server declares support for Group export operation in CapabilityStatement] test' do
    let(:runnable) { group.tests[1] }
    let(:no_export_capability_statement) do
      capability_statement_json = JSON.parse(capability_statement)
      capability_statement_json['rest'][0]['resource'][1]['operation'][0]['definition'] = ''
      capability_statement_json.to_json
    end

    it 'fails when CapabilityStatement can not be retrieved' do
      stub_request(:get, "#{bulk_server_url}/metadata")
        .to_return(status: 400)

      result = run(runnable, base_input)

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Bad response status: expected 200, 201, but received 400')
    end

    it 'fails when CapabilityStatement returned is not JSON' do
      stub_request(:get, "#{bulk_server_url}/metadata")
        .to_return(status: 200, body: 'not_json')

      result = run(runnable, base_input)

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Invalid JSON. ')
    end

    it 'fails when server does not declare support in CapabilityStatement' do
      stub_request(:get, "#{bulk_server_url}/metadata")
        .to_return(status: 200, body: no_export_capability_statement)

      result = run(runnable, base_input)

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Server CapabilityStatement did not declare support for export operation in Group resource')
    end

    it 'passes when server declares support in CapabilityStatement' do
      stub_request(:get, "#{bulk_server_url}/metadata")
        .to_return(status: 200, body: capability_statement)

      result = run(runnable, base_input)

      expect(result.result).to eq('pass')
    end
  end

  describe '[Bulk Data Server rejects $export request without authorization] test' do
    let(:runnable) { group.tests[2] }
    let(:bad_token_input) do
      base_input.merge( { bearer_token: nil } )
    end

    it 'skips if bearer_token not provided' do
      result = run(runnable, bad_token_input)

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('Could not verify this functionality when bearer token is not set')
    end

    it 'fails if client can $export without authorization' do
      stub_request(:get, "#{bulk_server_url}/Group/#{group_id}/$export")
        .to_return(status: 200)

      result = run(runnable, base_input)

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Bad response status: expected 401, but received 200')
    end

    it 'passes if client can not $export without authorization' do
      stub_request(:get, "#{bulk_server_url}/Group/#{group_id}/$export")
        .to_return(status: 401)

      result = run(runnable, base_input)
      expect(result.result).to eq('pass')
    end
  end

  describe '[Bulk Data Server returns "202 Accepted" and "Content-location" for $export] test' do
    let(:runnable) { group.tests[3] }

    it 'fails when server does not return "202 Accepted"' do
      stub_request(:get, "#{bulk_server_url}/Group/#{group_id}/$export")
        .with(headers: { 'Authorization' => "Bearer #{bearer_token}" })
        .to_return(status: 401)

      result = run(runnable, base_input)

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Bad response status: expected 202, but received 401')
    end

    it 'fails when server does not return "Content-Location" header' do
      stub_request(:get, "#{bulk_server_url}/Group/#{group_id}/$export")
        .with(headers: { 'Authorization' => "Bearer #{bearer_token}" })
        .to_return(status: 202)

      result = run(runnable, base_input)

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Export response headers did not include "Content-Location"')
    end

    it 'fails when no value for "Content-Location" header' do
      stub_request(:get, "#{bulk_server_url}/Group/#{group_id}/$export")
        .with(headers: { 'Authorization' => "Bearer #{bearer_token}" })
        .to_return(status: 202, headers: { 'content-location' => nil })

      result = run(runnable, base_input)

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Export response headers did not include "Content-Location"')
    end

    it 'passes when server returns both "202 Accepted" and "Content-location"' do
      stub_request(:get, "#{bulk_server_url}/Group/#{group_id}/$export")
        .with(headers: { 'Authorization' => "Bearer #{bearer_token}" })
        .to_return(status: 202, headers: { 'content-location' => polling_url })

      result = run(runnable, base_input)

      expect(result.result).to eq('pass')
    end
  end

  describe '[Bulk Data Server returns "202 Accepted" or "200 OK" for status check] test' do
    let(:input) { base_input.merge(polling_url: polling_url) }
    let(:runnable) { group.tests[4] }
    let(:headers) { {'content-type' => 'application/json'} } 
    let(:incomplete_status_response) do
      status_response_json = JSON.parse(status_response)
      status_response_json.delete('transactionTime')
      status_response_json.to_json
    end

    it 'skips when polling_url is not provided' do
      result = run(runnable)

      expect(result.result).to eq('skip')
      expect(result.result_message).to eq('Server response did not have Content-Location in header')
    end
    
    # Note: Test commented out as it takes three minutes to fail
    # it 'skips when server only returns "202 Accepted", and not "200 OK" in the allowed timeframe' do
    #   stub_request(:get, "#{polling_url}")
    #     .with(headers: { 'Authorization' => "Bearer #{bearer_token}" } )
    #     .to_return(status: 202)

    #   result = run(runnable, base_input)

    #   expect(result.result).to eq('skip')
    #   expect(result.result_message).to eq("Server took more than 180 seconds to process the request.")
    # end

    it 'fails when server does not return "202 Accepted" nor "200 OK' do
      stub_request(:get, polling_url.to_s)
        .with(headers: { 'Authorization' => "Bearer #{bearer_token}" })
        .to_return(status: 401)

      result = run(runnable, input)

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Bad response code: expected 200, 202, but found 401.')
    end

    it 'fails when server returns "200 OK" and impromper headers' do
      stub_request(:get, polling_url.to_s)
        .with(headers: { 'Authorization' => "Bearer #{bearer_token}" })
        .to_return(status: 200, body: 'invalid_status_response', headers: { 'bad' => 'headers' })

      result = run(runnable, input)

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Content-Type not application/json')
    end

    it 'fails when server returns "200 OK" and response body does not contain required attributes' do
      stub_request(:get, polling_url.to_s)
        .with(headers: { 'Authorization' => "Bearer #{bearer_token}" })
        .to_return(status: 200, body: incomplete_status_response, headers: headers)

      result = run(runnable, input)

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Complete Status response did not contain "transactionTime" as required')
    end

    it 'passes when server returns "202 Accepted" and response body contains required attributes' do
      stub_request(:get, polling_url.to_s)
        .with(headers: { 'Authorization' => "Bearer #{bearer_token}" })
        .to_return(status: 200, body: status_response, headers: headers)

      result = run(runnable, input)

      expect(result.result).to eq('pass')
    end
  end

  describe '[Bulk Data Server returns output with type and url for status complete] test' do
    let(:runnable) { group.tests[5] }
    let(:bad_status_output) do
      status_output_json = JSON.parse(status_output)
      status_output_json['output'][1].delete('type')
      status_output_json.to_json
    end

    it 'fails when response not found' do
      result = run(runnable)

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Bulk Data Server status response not found')
    end

    it 'fails when response does not contain output' do
      result = run(runnable, { status_response: '{"no_output":"!"}' })

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Bulk Data Server status response does not contain output')
    end

    it 'fails when output does not contain required attributes' do
      result = run(runnable, { status_response: bad_status_output })

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Output file did not contain "type" as required')
    end

    it 'passes when response contains output with required attributes' do
      result = run(runnable, { status_response: status_output })

      expect(result.result).to eq('pass')
    end
  end

  describe '[Bulk Data Server returns requiresAccessToken with value true] test' do
    let(:runnable) { group.tests[6] }
    let(:no_rAT_status_response) { '{"no_requiresAccessToken":"!"}' }
    let(:false_rAT_status_response) { '{"requiresAccessToken":false}' }

    it 'fails when response not found' do
      result = run(runnable)

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Bulk Data Server status response not found')
    end

    it 'fails when server response does not contain requireAccessToken' do
      result = run(runnable, { status_response: no_rAT_status_response })
      
      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Bulk Data file server access SHALL require access token')
    end

    it 'fails when server does not require access token' do
      result = run(runnable, { status_response: false_rAT_status_response })
      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Bulk Data file server access SHALL require access token')
    end

    it 'passes when server does require access token' do
      result = run(runnable, { status_response: status_response })
      expect(result.result).to eq('pass')
    end
  end

  # TODO: Write after HTTP Client delete support merged into core. 
  describe 'delete request tests' do

  end
end
