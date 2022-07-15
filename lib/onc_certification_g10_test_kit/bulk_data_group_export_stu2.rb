require_relative 'bulk_data_group_export'

module ONCCertificationG10TestKit
  class BulkDataGroupExportSTU2 < Inferno::TestGroup
    title 'Group Compartment Export Tests STU2'
    short_description 'Verify that the system supports Group compartment export.'
    description <<~DESCRIPTION
      Verify that system level export on the Bulk Data server follow the Bulk Data Access Implementation Guide
    DESCRIPTION

    id :bulk_data_group_export_stu2

    test from: 'bulk_data_group_export-g10_bulk_data_server_tls_version'

    test from: 'bulk_data_group_export-export_capability_statement',
      description: %(
        This test verifies that the Bulk Data Server declares support for
        Group/[id]/$export operation in its server CapabilityStatement.

        Given flexibility in the FHIR specification for declaring constrained
        OperationDefinitions, this test only verifies that the server declares
        any operation on the Group resource.  It does not verify that it
        declares the standard group export OperationDefinition provided in the
        Bulk Data specification, nor does it attempt to resolve any non-standard
        OperationDefinitions to verify if it is a constrained version of the
        standard OperationDefintion.

        This test will provide a warning if no operations are declared at
        `Group/[id]/$export`, via the
        `CapabilityStatement.rest.resource.operation.name` element.  It will
        also provide an informational message if an operation on the Group
        resource exists, but does not point to the standard OperationDefinition
        canonical URL:
        http://hl7.org/fhir/uv/bulkdata/OperationDefinition/group-export

        Additionally, this test provides a warning if the bulk data server does
        not include the following URL in its `CapabilityStatement.instantiates`
        element: http://hl7.org/fhir/uv/bulkdata/CapabilityStatement/bulk-data
      )

    test from: 'bulk_data_group_export-rejects_unauthorized_export'
    test from: 'bulk_data_group_export-export_returns_okay_and_content_header'
    test from: 'bulk_data_group_export-status_check_returns_okay'
    test from: 'bulk_data_group_export-status_complete_outputs_type_and_url'
    test from: 'bulk_data_group_export-delete_request_accepted'

    test do
      title 'Bulk Data Server supports "_outputFormat" query parameter'
      description <<~DESCRIPTION
        [_outputFormat](https://hl7.org/fhir/uv/bulkdata/export.html#query-parameters):
        The format for the requested Bulk Data files to be
        generated as per FHIR Asynchronous Request Pattern. Defaults to
        application/fhir+ndjson. The server SHALL support Newline Delimited
        JSON, but MAY choose to support additional output formats. The server
        SHALL accept the full content type of application/fhir+ndjson as well
        as the abbreviated representations application/ndjson and ndjson.
      DESCRIPTION

      include ExportKickOffPerformer

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
