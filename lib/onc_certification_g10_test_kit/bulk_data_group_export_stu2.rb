require_relative 'export_kick_off_performer'
require_relative 'bulk_data_group_export_stu1'

module ONCCertificationG10TestKit
  class BulkDataGroupExportSTU2 < BulkDataGroupExportSTU1
    title 'Group Compartment Export Tests STU2'
    short_description 'Verify that the system supports Group compartment export.'
    description <<~DESCRIPTION
      Verify that system level export on the Bulk Data server follow the Bulk Data Access Implementation Guide
    DESCRIPTION

    id :bulk_data_group_export_stu2

    test do
      title 'Bulk Data Server supports "_outputFormat" query parameter'
      description <<~DESCRIPTION
        _outputFormat: The format for the requested Bulk Data files to be generated as per FHIR Asynchronous Request Pattern. Defaults to application/fhir+ndjson. The server SHALL support Newline Delimited JSON, but MAY choose to support additional output formats. The server SHALL accept the full content type of application/fhir+ndjson as well as the abbreviated representations application/ndjson and ndjson.
      DESCRIPTION

      include ExportKickOffPerformer

      run do
        ['application/fhir+ndjson', 'application/ndjson', 'ndjson'].each do |format|
          perform_export_kick_off_request(params: "_outputFormat=#{format}")
          assert_response_status(202)
        end 
      end 
    end
  end
end
