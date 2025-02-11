require_relative '../../lib/onc_certification_g10_test_kit/bulk_data_group_export_cancel_stu2'

RSpec.describe ONCCertificationG10TestKit::BulkDataGroupExportCancelSTU2 do
  let(:group) { Inferno::Repositories::TestGroups.new.find('g10_bulk_data_export_cancel_stu2') }
  let(:suite_id) { 'g10_certification' }

  describe 'Status of cancelled export test' do
    let(:runnable) { group.tests.find { |test| test.id.to_s.end_with? 'bulk_data_poll_cancelled_export' } }
    let(:url) { 'http://example.com' }

    it 'fails if a 404 is not received' do
      stub_request(:get, url)
        .to_return(status: 202)

      result = run(runnable, cancelled_polling_url: url, bulk_server_url: 'foo', group_id: 'bar')

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/404/)
    end

    it 'fails if an OperationOutcome is not received' do
      stub_request(:get, url)
        .to_return(status: 404, body: '{}')

      result = run(runnable, cancelled_polling_url: url, bulk_server_url: 'foo', group_id: 'bar')

      expect(result.result).to eq('fail')
      expect(result.result_message).to match(/OperationOutcome/)
    end

    it 'passes if a 404 and valid OperationOutcome are received' do
      stub_request(:get, url)
        .to_return(status: 404, body: FHIR::OperationOutcome.new.to_json)
      allow_any_instance_of(runnable).to receive(:assert_valid_resource).and_return(true)

      result = run(runnable, cancelled_polling_url: url, bulk_server_url: 'foo', group_id: 'bar')

      expect(result.result).to eq('pass')
    end
  end
end
