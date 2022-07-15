require_relative 'bulk_data_group_export'

module ONCCertificationG10TestKit
  class BulkDataGroupExportSTU1 < BulkDataGroupExport
    title 'Group Compartment Export Tests STU1'
    short_description 'Verify that the system supports Group compartment export.'
    description <<~DESCRIPTION
      Verify that system level export on the Bulk Data server follow the Bulk Data Access Implementation Guide
    DESCRIPTION

    id :bulk_data_group_export_stu1
  end
end
