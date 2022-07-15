require_relative 'bulk_data_group_export'
require_relative 'export_kick_off_performer'

module ONCCertificationG10TestKit
  class BulkDataGroupExportSTU2 < Inferno::TestGroup
    title 'Group Compartment Export Tests STU2'
    short_description 'Verify that the system supports Group compartment export.'
    description <<~DESCRIPTION
      Verify that system level export on the Bulk Data server follow the Bulk Data Access Implementation Guide
    DESCRIPTION

    id :bulk_data_group_export_stu2

    test from: 'bulk_data_group_export-g10_bulk_data_server_tls_version'
    test from: 'bulk_data_group_export-export_capability_statement'
    test from: 'bulk_data_group_export-rejects_unauthorized_export'
    test from: 'bulk_data_group_export-export_returns_okay_and_content_header'
    test from: 'bulk_data_group_export-status_check_returns_okay'
    test from: 'bulk_data_group_export-status_complete_outputs_type_and_url'
    test from: 'bulk_data_group_export-delete_request_accepted'

    test do
      title 'Bulk Data Server supports "_outputFormat" query parameter'
      description <<~DESCRIPTION
        [_outputFormat](http://hl7.org/fhir/uv/bulkdata/STU2/export.html#query-parameters):
        The format for the requested Bulk Data files to be
        generated as per FHIR Asynchronous Request Pattern. Defaults to
        application/fhir+ndjson. The server SHALL support Newline Delimited
        JSON, but MAY choose to support additional output formats. The server
        SHALL accept the full content type of application/fhir+ndjson as well
        as the abbreviated representations application/ndjson and ndjson.
      DESCRIPTION

      include ExportKickOffPerformer

      input :bearer_token, :group_id, :bulk_server_url

      http_client :bulk_server do
        url :bulk_server_url
      end

      run do
        ['application/fhir+ndjson', 'application/ndjson', 'ndjson'].each do |format|
          perform_export_kick_off_request(params: "_outputFormat=#{format}")
          assert_response_status(202)

          delete_export_kick_off_request
        end
      end
    end
  end
end
