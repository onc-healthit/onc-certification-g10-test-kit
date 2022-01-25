require_relative '../../lib/g10_certification_test_kit/bulk_export_validation_tester'

class BulkExportValidationTesterClass
  include Inferno::DSL::HTTPClient
  extend Inferno::DSL::Configurable

  include BulkExportValidationTester

  def test_session_id
    nil
  end
end

RSpec.describe BulkExportValidationTester do
  let(:group) { BulkExportValidationTesterClass.new }
  let(:url) { 'https://example1.com' }
  let(:basic_body) { 'single line response_body' }
  let(:multi_line_body) { "multi\nline\nresponse\nbody\n" }
  let(:generic_block) { proc { |chunk| } }
  let(:streamed_chunks) { [] }
  let(:streamed_headers) { [] }
  let(:process_line_block) { proc { |chunk| streamed_chunks << ("#{chunk} touched") } }
  let(:process_headers_block) { proc { |response| streamed_headers << response[:headers][0].value } }
  let(:headers) { { 'Application' => 'expected' } }

  describe 'stream_ndjson' do
    it 'makes a stream request using the given endpoint' do
      stub_request(:get, url).to_return(status: 200)

      group.stream_ndjson(url, {}, generic_block, generic_block)

      expect(streamed_chunks.empty?)
      expect(streamed_headers.empty?)
      expect(group.response[:status]).to eq(200)
      expect(group.response[:headers].empty?)
      expect(group.response[:body].empty?)
    end

    it 'applies process_header once, upon reception of a single, one-line chunk' do
      stub_request(:get, url)
        .to_return(status: 200, body: basic_body, headers: headers)

      group.stream_ndjson(url, {}, generic_block, process_headers_block)

      expect(streamed_chunks.empty?)
      expect(streamed_headers).to eq(['expected'])
      expect(group.response[:headers][0].value).to eq(headers['Application'])
      expect(group.response[:body].empty?)
    end

    it 'applies process_chunk_line to single, one-line chunk of a stream' do
      stub_request(:get, url)
        .to_return(status: 200, body: basic_body)

      group.stream_ndjson(url, {}, process_line_block, generic_block)

      expect(streamed_chunks).to eq(["#{basic_body} touched"])
      expect(streamed_headers.empty?)
      expect(group.response[:headers].empty?)
    end

    it 'applies process_chunk_line to single, multi-line chunk of a stream' do
      stub_request(:get, url.to_s)
        .to_return(status: 200, body: multi_line_body)

      group.stream_ndjson(url, {}, process_line_block, generic_block)

      expect(streamed_chunks).to eq(["multi\n touched", "line\n touched", "response\n touched", "body\n touched"])
      expect(streamed_headers.empty?)
      expect(group.response[:headers].empty?)
    end
  end
end
