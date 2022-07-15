require_relative 'bulk_data_authorization'
require_relative 'bulk_data_group_export_stu2'
require_relative 'bulk_data_group_export_validation'

module ONCCertificationG10TestKit
  class MultiPatientAPIGroupSTU2 < Inferno::TestGroup
    title 'Multi-Patient Authorization and API STU2'
    short_title 'Multi-Patient API STU2'

    input_instructions %(
      Register Inferno as a bulk data client with the following information, and
      enter the client id and client registration in the appropriate fields.
      This set of tests only checks the Group export. Enter the group export
      information in the appropriate box.

      Register Inferno with the following JWK Set Url:

      * `#{Inferno::Application[:base_url]}/custom/g10_certification/.well-known/jwks.json`
    )

    description %(
      Demonstrate the ability to export clinical data for multiple patients in
      a group using [FHIR Bulk Data Access
      IG](https://hl7.org/fhir/uv/bulkdata/STU2/). This test uses [Backend Services
      Authorization](http://www.hl7.org/fhir/smart-app-launch/backend-services.html)
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
    id :multi_patient_api_stu2
    run_as_group

    input_order :bulk_server_url,
                :bulk_token_endpoint,
                :bulk_client_id,
                :bulk_scope,
                :bulk_encryption_method,
                :group_id,
                :bulk_patient_ids_in_group,
                :bulk_device_types_in_group,
                :lines_to_validate,
                :bulk_timeout

    group from: :bulk_data_authorization,
          description: <<~DESCRIPTION
            Bulk Data servers are required to authorize clients using the [Backend Service
            Authorization](http://www.hl7.org/fhir/smart-app-launch/backend-services.html)
            specification as defined in the [FHIR Bulk Data Access IG
            v2.0.0](https://hl7.org/fhir/uv/bulkdata/STU2/).

            In this set of tests, Inferno serves as a Bulk Data client that requests authorization
            from the Bulk Data authorization server.  It also performs a number of negative tests
            to validate that the authorization service does not improperly authorize invalid
            requests.

            This test returns an access token.
          DESCRIPTION

    group from: :bulk_data_group_export_stu2
    group from: :bulk_data_group_export_validation
  end
end
