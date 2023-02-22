require_relative 'bulk_data_group_export_stu1'
require_relative 'export_kick_off_performer'

module ONCCertificationG10TestKit
  class BulkDataGroupExportSTU2 < BulkDataGroupExportSTU1
    title 'Group Compartment Export Tests STU2'
    id :bulk_data_group_export_stu2

    config(options: { require_absolute_urls_in_output: true })
  end
end
