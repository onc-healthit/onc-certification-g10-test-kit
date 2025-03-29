The **ONC Certification (g)(10) Standardized API Test Kit** is a testing tool
for Health IT systems seeking to meet the requirements of the ONC [Standardized
API for Patient and Population Services criterion §
170.315(g)(10)](https://www.healthit.gov/test-method/standardized-api-patient-and-population-services)
in the ONC Health IT Certification Program. The following documentation provides information
on how to use and contribute to this test kit.

## Overview

This test kit validates conformance to the following implementation specifications required by the (g)(10) certification criterion:

* Health Level 7 (HL7®) Fast Healthcare Interoperability Resources (FHIR®) (v4.0.1)
* US Core Implementation Guide (v3.1.1, v4.0.0, v6.1.0, or v7.0.0)
* SMART Application Launch Framework Implementation Guide Release (v1.0.0, v2.0.0, or v2.2.0)
* HL7 FHIR Bulk Data Access (Flat FHIR) (v1.0.1, or v2.0.0)

## Using this Test Kit

* [Getting Started](https://github.com/onc-healthit/onc-certification-g10-test-kit/?tab=readme-ov-file#getting-started): Installation instructions for setting up and running this test kit locally.
* [Test Kit Walkthrough](Walkthrough.md): A step-by-step guide to using this test kit, including screenshots and detailed instructions for each testing scenario.
* [Testing FAQ](FAQ.md): Frequently asked questions about the tests in this test kit, including explanations of how specific resources are tested and the difference between test result states.
* [IE Browser](IE-Browser.md): A guide to using this test kit with legacy/unsupported versions of Internet Explorer when testing EHR systems that use IE as an embedded browser.

## Contributing to this Test Kit

Developers contributing to this test kit should be familiar with [authoring
Inferno Framework test suites](https://inferno-framework.github.io/docs/writing-tests/). The following guides provide additional
information about the design and implementation of this test kit to aid
in contributing to these tests:

* [Technical Overview](Technical-Overview.md): A guide to the architecture of this test kit, including test design principles, code organization, and relationship with other test kits.
* [SVAP Update Guide](SVAP-Update-Guide.md): Detailed instructions for developers on how to update this test kit when new versions of standards are approved through the SVAP process.
* [Terminology Update Guide](Terminology-Update-Guide.md): Detailed instructions on how to update terminology validation components used in this test kit.
* [Unusual Implementation Details](Unusual-Implementation-Details.md): Gotchas and special cases to be aware of when updating this test kit, including links to specific code examples.

## Reference Documents

* [Test Procedure Matrix](https://github.com/onc-healthit/onc-certification-g10-test-kit/raw/refs/heads/main/onc_certification_g10_matrix.xlsx): A matrix of test procedures and their associated test cases, providing a comprehensive view of the certification requirements covered by this test kit.

## Support

For questions or issues with this test kit, please reach out to the Inferno team
on the [#Inferno FHIR Zulip
channel](https://chat.fhir.org/#narrow/stream/179309-inferno).

Report bugs or provide suggestions in [GitHub Issues](https://github.com/onc-healthit/onc-certification-g10-test-kit/issues).
