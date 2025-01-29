require_relative 'version'

module ONCCertificationG10TestKit
  class Metadata < Inferno::TestKit
    id :onc_certification_g10_test_kit
    title 'ONC Certification (g)(10) Standardized API Test Kit'
    description <<~DESCRIPTION
      The ONC Certification (g)(10) Standardized API Test Kit is a testing tool for
      Health IT systems seeking to meet the requirements of the Standardized API for
      Patient and Population Services criterion § 170.315(g)(10) in the ONC
      Certification Program. It is an approved test method for the [§ 170.315(g)(10)
      test
      procedure](https://www.healthit.gov/test-method/standardized-api-patient-and-population-services#test_procedure).
      <!-- break -->

      Systems may adopt later versions of standards than those named in the rule as
      approved by the ONC Standards Version Advancement Process (SVAP).  Please note
      that US Core Implementation Guide v.7.0.0 should only be used with SMART
      App Launch Guide v2.0.0 or above due to granular scope support
      requirements within this version of US Core.

      Please select which approved version of each standard to use, and click 'Create
      Test Session' to begin testing.

      This test kit includes a [simulated conformant FHIR
      API](https://inferno.healthit.gov/reference-server/) that can be used to
      demonstrate success for all tests. This simulated API is open source and is
      available on
      [GitHub](https://github.com/inferno-framework/inferno-reference-server). Visit
      the
      [walkthrough](https://github.com/onc-healthit/onc-certification-g10-test-kit/wiki/Walkthrough)
      for a demonstration of using these tests against the provided simulated FHIR
      API.

      ## Status

      The ONC Certification (g)(10) Standardized API is actively developed and updates
      are released monthly.

      The test kit currently tests all requirements for the [Standardized API for
      Patient and Population Services criterion §
      170.315(g)(10)](https://www.healthit.gov/test-method/standardized-api-patient-and-population-services),
      including updates from the [HTI-1 Final
      Rule](https://www.healthit.gov/topic/laws-regulation-and-policy/health-data-technology-and-interoperability-certification-program).
      This includes:
      - SMART App Standalone Launch with full system access
      - SMART App Standalone Launch with limited system access
      - SMART App Standalone Launch with OpenID Connect
      - SMART App EHR Launch with user scopes
      - SMART App EHR Launch with patient scopes
      - SMART App Launch Invalid AUD Parameter
      - SMART App Launch Invalid Access Token Request
      - SMART App Launch Token Introspection
      - SMART App Launch v1 and v2 scopes
      - SMART App Launch finer-grained scope access
      - Support for Capability Statement
      - Support for all US Core Profiles
      - Searches required for each resource
      - Support for Must Support Elements
      - Profile Validation
      - Reference Validation
      - Export of multiple patients using the FHIR Bulk Data Access IG

      See the test descriptions within the test kit for detail on the specific
      validations performed as part of testing these requirements.

      ## Repository and Resources

      The ONC Certification (g)(10) Standardized API Test Kit can be [downloaded from
      its GitHub
      repository](https://github.com/onc-healthit/onc-certification-g10-test-kit),
      where additional resources and documentation are also available to help users
      get started with the testing process. The repository
      [Wiki](https://github.com/onc-healthit/onc-certification-g10-test-kit/wiki/FAQ)
      provides a
      [FAQ](https://github.com/onc-healthit/onc-certification-g10-test-kit/wiki/FAQ)
      for testers, and the
      [Releases](https://github.com/onc-healthit/onc-certification-g10-test-kit/releases)
      page provides information about each new release.

      ## Providing Feedback and Reporting Issues

      We welcome feedback on the tests, including but not limited to the following areas:

      - Validation logic, such as potential bugs, lax checks, and unexpected failures.
      - Requirements coverage, such as requirements that have been missed, tests that
        necessitate features that the IG does not require, or other issues with the
        interpretation of the IG's requirements.
      - User experience, such as confusing or missing information in the test UI.

      Please report any issues with this set of tests in the [issues
      section](https://github.com/onc-healthit/onc-certification-g10-test-kit/issues)
      of the repository.
    DESCRIPTION
    suite_ids [:g10_certification]
    tags ['SMART App Launch', 'US Core', 'Bulk Data']
    last_updated '2025-01-29'
    version VERSION
    maturity 'High'
    authors ['Stephen MacVicar']
    repo 'https://github.com/onc-healthit/onc-certification-g10-test-kit'
  end
end
