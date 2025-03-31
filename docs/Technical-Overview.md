This document provides technical information about the design of this test kit
and is intended to serve multiple purposes:
* To guide individuals who are interested in contributing to this project.
* To assist in the onboarding of new development team members.
* To support the long-term continuity of this project by enabling an
  effective transfer of this software to new stewards.

This document does not provide detailed instructions on how to use
an Inferno test kit, the contents of the (g)(10) Certification Criteria,
basics of the Inferno Framework, or details on how to use Ruby, Docker,
or other tools. Developers are expected to have at least a basic understanding
of all these topics. Please refer to the References section of this document
for links to more information about these topics.

Please note that the focus of this document is on features that are specific to
this test kit and it does not provide a detailed explanation of common Inferno
Framework functionality.

## Test Design Principles and features

Prior to making any updates or additions to these tests, developers should
be aware of the general principles that guided development of the existing tests
to ensure a consistent test experience for users. While judgment is required
by the test developer to determine the appropriate level of testing for each
requirement, it is important to provide a consistent approach across the entire
test kit to aid users in understanding the results of the tests.

Tests for this test kit have been designed with the following principles:
* Easy testing: Users should be able to run the tests with minimal input or
  configuration, and tests should complete in a reasonable amount of time.
* Limit extraneous constraints: The tests should not place additional constraints
  on the system under test.
* Reuse existing tests when possible: Reuse tests from test kits that target
  implementation guides that are required within this test kit.

The design of the tests within this test kit reflects these principles:
* Systems do not need to load a specific set of example data; instead, the
  tests allow systems to provide their own data that exhibits all required
  functionality.
* Tests are written to verify the use of all required specifications together
  as described by the certification criterion, instead of requiring systems to
  independently test each. For example, tests for demonstrating the Single
  Patient API also require use of a SMART App Launch validated bearer token. This
  enhances the realism of the test, but also ensures that the system under test is
  able to support the full range of required functionality.
* When a test involves multiple standards, they are written intelligently
  so that only the versions of the standard that were selected by the
  tester apply.
* Not all requirements provided by the certification criterion or the
  underlying standards can be tested using an automated tool. In these cases,
  the system under test can attest that the requirement is met, or a tester
  can choose to provide a method for visual inspection. Tests are provided
  at the end of the test kit to ensure these are accomplished.

The (g)(10) Test Kit manages this complexity through standard software design
practices and approaches, leveraging the functionality provided by the Ruby
programming language. While this code is intended to be accessible to
developers new to the Ruby language, developers are expected to learn the basics
of Ruby development before attempting to alter these tests. This test kit also
uses RSpec to "unit test" components of these tests, and developers are expected
to learn the basics of RSpec as well.

## Relationship with Other Test Kits

The ONC (g)(10) Certification Criterion requires the implementation of several
FHIR Implementation Guides, while providing guidance on how to support these
test kits to accomplish the specific requirements of the certification
criterion. In order to facilitate testing systems independently of the (g)(10)
Certification requirements, each of these Implementation Guides also has a
stand-alone test kit. The (g)(10) Test Kit then imports tests defined in these
test kits and integrates them into a single cohesive test procedure, while also
further constraining their implementation to meet any (g)(10)-specific
requirements.

*Please note that the Multi-Patient API tests do not currently reuse
the Bulk Data Access Test Kit. A future version of this test kit may reuse the
Bulk Data Access Test Kit.*

The specific test kits that are imported into this test kit include:

1. **[US Core Test Kit](https://github.com/inferno-framework/us-core-test-kit)**:
  Data access within the Single Patient API tests in this Test Kit is
  imported from the US Core Test Kit.  
2. **[SMART App Launch Test Kit](https://github.com/inferno-framework/smart-app-launch-test-kit)**: All
  Single Patient API authorization tests are imported from the SMART App Launch Test Kit.

## Test Kit Code Organization

The (g)(10) Test Kit follows general Ruby conventions for applications and
libraries. It is organized into several main directories:

- `.github`: Contains workflows for integrating with GitHub's automated tools
- `bin`: Contains scripts for generating local terminologies.
- `config`: Contains configuration files for the test kit.
- `data`: Contains runtime data for the test kit, such as local database files
- `docs`: Contains documentation for this test kit.
- `lib`: Contains the main logic for the test kit, including the test cases and helper functions.
- `lib/inferno`: Contains patches to the Inferno Framework to accommodate special cases.
- `lib/onc_certification_g10_test_kit`: Contains the main tests for the test kit
- `resources`: Contains static resources such as FHIR profiles and test data.
- `spec`: Contains the RSpec test cases for the test kit.
- `tmp`: Temporary files used by the test kit at runtime.

The (g)(10) Test Kit contains a single suite of tests, which is capable of testing
any valid combination of approved standards for certification. This suite
is defined in `lib/onc_certification_g10_test_kit.rb` and imports all necessary
tests from both external test kits and from within the (g)(10) Test Kit itself.

## Testing Code Changes

This test kit includes comprehensive "self testing" functionality to provide
confidence that the tests perform as expected. Prior to committing changes to
this test kit, developers should ensure that both RSpec tests and End-to-End
tests pass.

### RSpec Tests

The test kit contains many "unit" tests within the `spec` directory. These
tests are written in RSpec, and can be run with the following command:

```bundle exec rake```

These tests should be run after any changes to the tests, and must pass before
any changes to the tests are merged into the main branch. It is not expected
that the code base achieves 100% test coverage; instead, the team has followed a
common sense approach to testing components that 1) are complicated or 2) are
likely to change.

### End-to-End testing

Besides the unit tests provided within this test kit, after each update
the tests should be validated against a complete server implementation
that is known to be correct. The Inferno Reference Server provides this functionality,
and contains data that passes all of these tests. Note that if test changes
have been made that require data on the Reference Server to change as well,
that data set needs to be updated.


## FHIR and Terminology Validation

One important difference between this test kit and many others is that terminology
validation is performed within test logic instead of automatically through validating
resources within the HL7 FHIR Validator.
This is done to ensure that no external service runtime dependencies exist within this test kit
and that the test kit authors have complete control over which version of terminology systems
are validated against. However, this also means that users that download this test kit
must download and prepare terminology packages for use with the test kit, and the terminology
definitions must be updated periodically.

The README in this repository provides instructions on how to prepare local terminology
files for users that download this test kit and run it locally.

This test kit allows users to run the test kit even if the terminology files have not
been installed or have been incorrectly installed. Local terminology files are validated to ensure
that they are correct and up-to-date against a manifest file that is stored within
this repository. This manifest file needs to be periodically updated as new versions
of terminology packages are released and as policy changes are made.

Please visit the [Terminology Update Guide](Terminology-Update-Guide) for instructions on
how to update the terminology.
