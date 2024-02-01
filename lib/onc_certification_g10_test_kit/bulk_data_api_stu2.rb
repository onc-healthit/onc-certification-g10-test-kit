require 'bulk_data_test_kit/v2.0.0/bulk_data_test_suite'

module ONCCertificationG10TestKit
  class BulkDataAPIGroupSTU2 < Inferno::TestGroup
    id :g10_bulk_data_v200
    title 'Bulk Data Authorization and API v2.0.0'
    short_title 'Bulk Data API'
    run_as_group

    description %(
      The Bulk Data Access Test Kit is a testing tool that will demonstrate the ability to export clinical data for multiple patients. This test kit is split into
      two different types of bulk patient export: the export of patients in a specified group and the export of all patients, using [FHIR Bulk Data Access
      IG](http://hl7.org/fhir/uv/bulkdata/STU1.0.1/). This test kit uses [Backend Services
      Authorization](http://hl7.org/fhir/uv/bulkdata/STU1.0.1/authorization/index.html)
      to obtain an access token from the server. After authorization, a group
      level bulk data export request and a patient level bulk data export request (to request all patients) 
      are initialized. Finally, the tests readexported NDJSON files from the server and validate the resources in
      each file. To run these tests successfully, the selected group or patient export is
      required to have every type of resource mapped to [USCDI data
      elements](https://www.healthit.gov/isa/us-core-data-interoperability-uscdi).
      Additionally, it is expected the server will provide Encounter,
      Location, Organization, and Practitioner resources as they are
      referenced as must support elements in required resources.

      To get started, please first register Inferno with the following JWK Set
      Url:

      * `#{Inferno::Application[:base_url]}/custom/g10_certification/.well-known/jwks.json`

      Systems must pass all tests in order to qualify for ONC certification.
    )

    fhir_client :bulk_server do
      url :bulk_server_url
    end

    http_client :bulk_server do
      url :bulk_server_url
    end
    
    group from: 'bulk_data_smart_backend_services'
    group from: 'bulk_data_export_tests_v200'
  end
end