require_relative 'bulk_data_authorization'
require_relative 'bulk_data_group_export'
require_relative 'bulk_data_group_export_validation.rb'

module G10CertificationTestKit
  class MultiPatientAPIGroup < Inferno::TestGroup
    title 'Multi-Patient API'
    description %(
      Demonstrate the ability to export clinical data for multiple patients in
      a group using [FHIR Bulk Data Access
      IG](https://hl7.org/fhir/uv/bulkdata/). This test uses [Backend Services
      Authorization](https://hl7.org/fhir/uv/bulkdata/authorization/index.html)
      to obtain an access token from the server. After authorization, a group
      level bulk data export request is initialized. Finally, this test reads
      exported NDJSON files from the server and validates the resources in
      each file. To run the test successfully, the selected group export is
      required to have every type of resource mapped to [USCDI data
      elements](https://www.healthit.gov/isa/us-core-data-interoperability-uscdi).
      Additionally, it is expected the server will provide Encounter,
      Location, Organization, and Practitioner resources as they are
      referenced as must support elements in required resources.
    )
    id :multi_patient_api
    run_as_group

    group from: :bulk_data_authorization
    group from: :bulk_data_group_export
    group from: :bulk_data_group_export_validation
  end
end