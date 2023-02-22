require_relative 'export_kick_off_performer'

module ONCCertificationG10TestKit
  class BulkDataGroupExportParameters < Inferno::TestGroup
    id :g10_bulk_data_export_parameters
    title 'Group Compartment Export Parameters Tests'
    description %(
      TODO
    )

    input :bearer_token
    input :bulk_server_url,
          title: 'Bulk Data FHIR URL',
          description: 'The URL of the Bulk FHIR server.'
    input :group_id,
          title: 'Group ID',
          description: 'The Group ID associated with the group of patients to be exported.'

    http_client :bulk_server do
      url :bulk_server_url
    end

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

      id :output_format_in_export_response

      include ExportKickOffPerformer

      input :bearer_token, :group_id, :bulk_server_url

      run do
        ['application/fhir+ndjson', 'application/ndjson', 'ndjson'].each do |format|
          perform_export_kick_off_request(params: { _outputFormat: format })
          assert_response_status(202)

          delete_export_kick_off_request
        end
      end
    end
  end
end
