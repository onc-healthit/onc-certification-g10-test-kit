require_relative '../../lib/onc_certification_g10_test_kit/bulk_data_group_export_parameters'

RSpec.describe ONCCertificationG10TestKit::BulkDataGroupExportParameters do
  let(:group) { Inferno::Repositories::TestGroups.new.find('g10_bulk_data_export_parameters') }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:test_session) { repo_create(:test_session, test_suite_id: 'g10_certification') }
  let(:export_url) { "#{bulk_server_url}/Group/#{group_id}/$export" }
  let(:bulk_server_url) { 'https://example.com/fhir' }
  let(:bearer_token) { 'some_bearer_token_alphanumeric' }
  let(:group_id) { '1219' }
  let(:polling_url) { 'https://redirect.com' }
  let(:input) do
    {
      bulk_server_url:,
      bearer_token:,
      group_id:
    }
  end

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

  describe 'Bulk Data Server supports "_outputFormat" query parameter test' do
    let(:runnable) { group.tests.find { |test| test.id.to_s.end_with? 'output_format_in_export_response' } }
    let(:long_format_req) do
      stub_request(:get, "#{export_url}?_outputFormat=application%2Ffhir%2Bndjson")
        .to_return(status: 202, headers: { 'Content-Location' => polling_url })
    end
    let(:medium_format_req) do
      stub_request(:get, "#{export_url}?_outputFormat=application%2Fndjson")
        .to_return(status: 202, headers: { 'Content-Location' => polling_url })
    end
    let(:short_format_req) do
      stub_request(:get, "#{export_url}?_outputFormat=ndjson")
        .to_return(status: 202, headers: { 'Content-Location' => polling_url })
    end
    let(:delete_export_req) do
      stub_request(:delete, polling_url)
        .to_return(status: 202)
    end

    it 'fails when server does not support any ndjson content types' do
      stub_request(:get, "#{export_url}?_outputFormat=application%2Ffhir%2Bndjson")
        .to_return(status: 400)

      result = run(runnable, input)

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Unexpected response status: expected 202, but received 400')
    end

    it 'fails when server does not support deleting previous request' do
      stub_request(:delete, polling_url)
        .to_return(status: 400)

      long_format_req
      result = run(runnable, input)

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Unexpected response status: expected 202, but received 400')
    end

    it 'fails when server does not support application/ndjson or ndjson content type' do
      stub_request(:get, "#{export_url}?_outputFormat=application%2Fndjson")
        .to_return(status: 400)

      long_format_req
      delete_export_req

      result = run(runnable, input)

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Unexpected response status: expected 202, but received 400')
      expect(delete_export_req).to have_been_made.once
    end

    it 'fails when server only does not support ndjson content type' do
      stub_request(:get, "#{export_url}?_outputFormat=ndjson")
        .to_return(status: 400)

      long_format_req
      medium_format_req
      delete_export_req

      result = run(runnable, input)

      expect(result.result).to eq('fail')
      expect(result.result_message).to eq('Unexpected response status: expected 202, but received 400')
      expect(delete_export_req).to have_been_made.twice
    end

    it 'passes when server supports all ndjson content types and can delete each request' do
      long_format_req
      medium_format_req
      short_format_req
      delete_export_req

      result = run(runnable, input)

      expect(result.result).to eq('pass')
      expect(delete_export_req).to have_been_made.at_least_times(3)
    end
  end

  describe 'Bulk Data Server supports "_since" query parameter test' do
    let(:runnable) { group.tests.find { |test| test.id.to_s.end_with? 'g10_since_in_export_response' } }

    it 'fails if _since is not a valid FHIR instant' do
      result = run(runnable, input.merge(since_timestamp: 'abc'))

      expect(result.result).to eq('fail')
      expect(result.result_message).to include('is not a valid [FHIR instant]')
    end

    it 'passes if the server responds with a 202 to the kickoff request' do
      timestamp = Time.now.iso8601
      kickoff_request =
        stub_request(:get, "#{export_url}?_since=#{timestamp}")
          .to_return(status: 202, headers: { 'Content-Location' => polling_url })

      delete_request =
        stub_request(:delete, polling_url)
          .to_return(status: 202)

      result = run(runnable, input.merge(since_timestamp: timestamp))

      expect(result.result).to eq('pass')
      expect(kickoff_request).to have_been_made.once
      expect(delete_request).to have_been_made.once
    end
  end
end
