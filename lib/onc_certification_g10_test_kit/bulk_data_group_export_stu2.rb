require_relative 'bulk_data_group_export_stu1'
require_relative 'export_kick_off_performer'

module ONCCertificationG10TestKit
  class BulkDataGroupExportSTU2 < BulkDataGroupExportSTU1
    title 'Group Compartment Export Tests STU2'
    id :bulk_data_group_export_stu2

    config(options: { require_absolute_urls_in_output: true })

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

    test do
      title 'Bulk Data Server returns a 404 and OperationOutcome for polling requests to cancelled exports'
      description <<~DESCRIPTION
        > Following the delete request, when subsequent requests are made to the
          polling location, the server SHALL return a 404 Not Found error and an
          associated FHIR OperationOutcome in JSON format.

        http://hl7.org/fhir/uv/bulkdata/STU2/export.html#bulk-data-delete-request
      DESCRIPTION

      id :bulk_data_poll_cancelled_export

      input :cancelled_polling_url

      run do
        skip 'No polling url available' unless cancelled_polling_url.present?

        get(cancelled_polling_url, headers: { authorization: "Bearer #{bearer_token}", accept: 'application/json' })

        assert_response_status(404)

        assert_valid_json(response[:body])
        response_body = JSON.parse(response[:body])

        assert response_body['resourceType'] == 'OperationOutcome', 'Server did not return an OperationOutcome'
        assert_valid_resource(resource: FHIR::OperationOutcome.new(response_body))
      end
    end
  end
end
