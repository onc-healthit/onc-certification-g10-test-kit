require 'smart_app_launch_test_kit'
require 'us_core'

module G10CertificationTestKit
  class G10CertificationSuite < Inferno::TestSuite
    title '2015 Edition Cures Update - Standardized API Testing'

    group from: 'smart-smart_full_standalone_launch' do
      title 'Standalone Patient App'
      description %(
        This scenario demonstrates the ability of a system to perform a Patient
        Standalone Launch to a [SMART on
        FHIR](http://www.hl7.org/fhir/smart-app-launch/) confidential client
        with a patient context, refresh token, and [OpenID Connect
        (OIDC)](https://openid.net/specs/openid-connect-core-1_0.html) identity
        token. After launch, a simple Patient resource read is performed on the
        patient in context. The access token is then refreshed, and the Patient
        resource is read using the new access token to ensure that the refresh
        was successful. The authentication information provided by OpenID
        Connect is decoded and validated, and simple queries are performed to
        ensure that access is granted to all USCDI data elements.
      )

      run_as_group
    end

    group do
      title 'TODO: Limited App'
      description %(
        This scenario demonstrates the ability to perform a Patient Standalone
        Launch to a [SMART on FHIR](http://www.hl7.org/fhir/smart-app-launch/)
        confidential client with limited access granted to the app based on user
        input. The tester is expected to grant the application access to a
        subset of desired resource types.
      )

      test do
        title 'TODO'

        run { pass }
      end
    end

    group from: 'smart-smart_full_ehr_launch' do
      title 'EHR Practitioner App'
      description %(
        Demonstrate the ability to perform an EHR launch to a [SMART on
        FHIR](http://www.hl7.org/fhir/smart-app-launch/) confidential client
        with patient context, refresh token, and [OpenID Connect
        (OIDC)](https://openid.net/specs/openid-connect-core-1_0.html) identity
        token. After launch, a simple Patient resource read is performed on the
        patient in context. The access token is then refreshed, and the Patient
        resource is read using the new access token to ensure that the refresh
        was successful. Finally, the authentication information provided by
        OpenID Connect is decoded and validated.
      )

      run_as_group
    end

    group do
      id :single_patient_api
      title 'Single Patient API'
      description %(
        For each of the relevant USCDI data elements provided in the
        CapabilityStatement, this test executes the [required supported
        searches](http://www.hl7.org/fhir/us/core/STU3.1.1/CapabilityStatement-us-core-server.html)
        as defined by the US Core Implementation Guide v3.1.1. The test begins
        by searching by one or more patients, with the expectation that the
        Bearer token provided to the test grants access to all USCDI resources.
        It uses results returned from that query to generate other queries and
        checks that the results are consistent with the provided search
        parameters. It then performs a read on each Resource returned and
        validates the response against the relevant
        [profile](http://www.hl7.org/fhir/us/core/STU3.1.1/profiles.html) as
        currently defined in the US Core Implementation Guide. All MUST SUPPORT
        elements must be seen before the test can pass, as well as Data Absent
        Reason to demonstrate that the server can properly handle missing data.
        Note that Encounter, Organization and Practitioner resources must be
        accessible as references in some US Core profiles to satisfy must
        support requirements, and those references will be validated to their US
        Core profile. These resources will not be tested for FHIR search
        support.
      )
      run_as_group

      input :url,
            title: 'FHIR Endpoint',
            description: 'URL of the FHIR endpoint used by SMART applications',
            default: 'https://inferno.healthit.gov/reference-server/r4'
      input :bearer_token, optional: true, locked: true

      fhir_client do
        url :url
        bearer_token :bearer_token
      end

      test do
        id :preparation
        title 'Test preparation'
        input :standalone_access_token, optional: true, locked: true
        input :ehr_access_token, optional: true, locked: true
        # input :standalone_refresh_token, optional: true, locked: true
        # input :ehr_refresh_token, optional: true, locked: true

        output :bearer_token

        run do
          output bearer_token: standalone_access_token.presence || ehr_access_token.presence
        end
      end

      USCore::USCoreTestSuite.groups.each do |group|
        id = group.ancestors[1].id
        group from: id
      end
    end

    group do
      title 'TODO: Multi-Patient API'
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

      test do
        title 'TODO'

        run { pass }
      end
    end

    group do
      title 'TODO: Other'
      description %(
        Not all requirements that need to be tested fit within the previous
        scenarios. The tests contained in this section addresses remaining
        testing requirements. Each of these tests need to be run independently.
        Please read the instructions for each in the 'About' section, as they
        may require special setup on the part of the tester.
      )

      test do
        title 'TODO'

        run { pass }
      end
    end
  end
end
