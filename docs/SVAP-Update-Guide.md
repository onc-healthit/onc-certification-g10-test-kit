This document guides developers through the process of developing and
incorporating new and updated tests for the yearly Standards Version Advancement
Process (SVAP) updates to the (g)(10) certification criterion.

Prior to reviewing this document, the developer is expected to be familiar with
using the US Core Test Kit and building test kits using the Inferno Framework.
Please review the [Technical Overview](Technical-Overview.md) document for a
high-level overview of the test kit's design.

## Overview

The **§170.315(g)(10) Standardized API for patient and population services** certification
criterion requires systems to implement the following implementation specifications:

* US Core Implementation Guide
* SMART Application Launch Framework Implementation Guide Release
* HL7 FHIR Bulk Data Access (Flat FHIR)

New versions of these specifications are approved on an annual basis by ASTP through
the SVAP process. The new versions of these standards define many of the changes
that will need to be addressed in the (g)(10) certification test kit. In addition,
ASTP updates the [test procedure](https://www.healthit.gov/test-method/standardized-api-patient-and-population-services#test_procedure) and the
[certification companion guide](https://www.healthit.gov/test-method/standardized-api-patient-and-population-services#ccg) for each new version of SVAP which
need to be reflected in the updated tests.

Tests within the (g)(10) Test Kit are either imported from **Component Test
Kits** or provided within the (g)(10) Test Kit. Component Test Kits target
specific implementation specifications, independent of the certification
criterion. This enables broader use of these tests outside of the context of
certification and also provides an avenue to publish tests against new versions
of these specifications prior to inclusion into the certification program. The
Component Test Kits relevant to this test kit are the [US Core Test Kit](https://github.com/inferno-framework/us-core-test-kit)
and the [SMART App Launch Test Kit](https://github.com/inferno-framework/smart-app-launch-test-kit).

*Note: Tests for the Multi-Patient API requirement within the (g)(10)
certification criterion are provided within the (g)(10) Test Kit. While there
is a [Bulk Data Test
Kit](https://github.com/inferno-framework/bulk-data-test-kit) that has been
published, tests from that test kit have not yet been imported into this test
kit. Multi-Patient API tests are implemented directly within this test kit.*

The steps involved in updating the test kits are broadly:

1. Update Component Test Kits
2. Incorporate US Core Test Updates
3. Incorporate SMART App Launch Test Updates 
4. Update Bulk Data Tests
5. Complete (g)(10) Test Kit
6. Validate Updates against Reference Server


## Step 1. Update Component Test Kits

The best place to start is to update the Component Test Kits, as necessary.
These test kits separate tests for different versions of the specifications
into different suites. For example, the US Core Test Kit has a suite for
testing to US Core v6.1.0 and a suite for testing to US Core v7.0.0.

The [US Core Test Kit](https://github.com/inferno-framework/us-core-test-kit) includes
a [Version Update Guide](https://github.com/inferno-framework/us-core-test-kit/wiki/Version-Update-Guide) to support developers in updating that test kit, as the
complexity of US Core updates can be significant.

Updating the [SMART App Launch Test Kit](https://github.com/inferno-framework/smart-app-launch-test-kit) is relatively straightforward, as the test kit is
based on the [SMART App Launch Framework](https://smart-on-fhir.github.io/app-launch/)
specification, which is a relatively stable specification. Developers
can follow the existing pattern that is exhibited in the source code for creating
new suites that support testing new versions of that standard.

Once updated, new versions of the test kit gem can be published and imported
into the (g)(10) Test Kit.

## Step 2. Incorporate US Core Test Updates

Import a new version of the test kit, which includes new tests for the new
version of US Core, by updating the `onc_certification_g10_test_kit.gemspec`.

The primary location where US Core testing occurs is in the 'Single Patient API' group.
This group imports tests from the US Core Test kit, while applying special constraints
on these tests that apply to the (g)(10) certification. The group is defined in
`./lib/onc_certification_g10_test_kit/single_patient_us_core_{x}_api_group.rb`.
To create the new group, copy the `./lib/onc_certification_g10_test_kit/single_patient_us_core_6_api_group.rb` to a new file, replacing `6` with the new version of
the implementation guide that is supported.

A handful of things need to be updated in the new file:

**US Core Version Number**: The US Core version number, for instance "6.1.0", is
used in numerous locations within this file. This version number needs to be
updated to the accurate version number.

**US Core Module**: "USCoreV610" module is currently used when referencing the
USCoreTestSuite. This needs to be updated to the appropriate module.

**required_profiles**: This is an array of necessary profiles that the server
must declare in the CapabilityStatement. This array is used in the "Capability
Statement lists support for required US Core Profiles" test to detect any
profiles that are absent from this array. This array should be updated to
include additional profiles as mandated by the USCDI Guidance in the latest
version of US Core.

**required_resources (deprecated)**: Like the required_profile, this is an array of FHIR resource types that the server must declare in the Capability Statement. This is only applicable to US Core v3.1.1 and has been deprecated since the release of US Core v4.0.0.

## Step 3. Incorporate SMART App Launch Test Updates

Import a new version of the SMART App Launch test kit, which includes new tests for the new
version of SMART App Launch, by updating the `onc_certification_g10_test_kit.gemspec`.

SMART App Launch behavior is included throughout the test kit in several different
groups. Depending on the situation, different strategies have been used
to test different features from different versions of the specification.
The developer will need to identify which tests in the (g)(10) test kit
are impacted and update the tests accordingly. They may use the same
patterns that have been used to incorporate v1.0.0, v2.0.0 and v2.2.0 of
the SMART App Launch specification.


## Step 4: Update Bulk Data Tests

Bulk Data tests are in the following test groups:
* multi_patient_api_stu1
* multi_patient_api_stu2

Create a new group for new versions of the bulk data test kit (e.g.
multi_patient_api_stu3 would be appropriate for a v3 of bulk data). Update
the tests as needed.

Additionally, there are some test modules that need to be updated with the new US Core version
adopted by the (g)(10) procedure:

**bulk_data_group_export_validation**: This group includes validation tests for each resource type. If the new US Core IG requires an additional resource type or profile, new validation test should be added to this group. For instance, g10_us_core_6_bulk_specimen_validation adds a validation test for Specimen resources in bulk export for US Core v6.1.0.

**resource_selector**: Bulk Data Export is resource type-based, while US Core validation is profile-based. One resource type may have multiple required US Core profiles, such as Observation. This module is used by the bulk data export validation test to select the correct profiles for each exported resource in the NDJSON export file. It should be updated.


## Step 5. Complete (g)(10) Test Kit Updates

Numerous files require updates for the (g)(10) test kit. We'll begin with the test suite file named `g10_certification_suite.rb`.


**Import Test Groups**: The initial step is to import the relevant test group files. This can be accomplished by adding the corresponding test group files in the 'require' section. For instance, to import the 'Single Patient US Core 6' test group, you would add this line:

```ruby
require_relative 'single_patient_us_core_6_api_group'
```

**Update Error Filters**: In addition to the ERROR_FILTERs defined in the US
Core Test Kit, the (g)(10) Test Kit also has its own unique ERROR_FILTERS
array. Any extra error filter expressions should be added to this array.

**Set up Validator with US Core version**: The variable
"us_core_message_filters" is used to identify the ERROR_FILTER based on the US
Core version. This list should be updated whenever a new US Core version is
adopted.

The variable "profile_version" translates the US Core "full version" to the US
Core "reformatted version". For example, "v6.1.0" is the full version and "v610"
is the reformatted version. The reformatted version is used in the Test Suite's
module name. These translations assist in identifying the correct test suite
module from the US Core version.

The following code segments set up a validator for each US Core version. New US
Core versions should be added to this array:

```ruby
    [
      G10Options::US_CORE_3_REQUIREMENT,
      G10Options::US_CORE_4_REQUIREMENT,
      G10Options::US_CORE_5_REQUIREMENT,
      G10Options::US_CORE_6_REQUIREMENT

    ].each do |us_core_version_requirement|
      setup_validator(us_core_version_requirement)
    end
```

**Update Suite Options**: The variable "suite_option" holds a list of
Implementation Guides (IGs) that can be selected for testing. This list should
also be expanded to include new versions of adopted Implementation Guides. For
instance, the options for US Core are:

```ruby
list_options: [
                {
                  label: 'US Core 3.1.1 / USCDI v1',
                  value: G10Options::US_CORE_3
                },
                {
                  label: 'US Core 4.0.0 / USCDI v1',
                  value: G10Options::US_CORE_4
                },
                {
                  label: 'US Core 6.1.0 / USCDI v3',
                  value: G10Options::US_CORE_6
                }
              ]
```

There are similar option lists for SMART App Launch IG and Bulk Data IG.

**Update G10 Options**: The "g10_options.rb" file contains constants for the
implementation guides that have been adopted by the (g)(10) test procedure.
This includes names, version numbers, and requirements. When a new version is
incorporated into the test procedure, this file should be updated accordingly.


**Update Short ID Mappings**: Each (g)(10) test has a unique short id to ensure
that when tests are inserted in the middle of a test group, the short ids for
existing tests remain unchanged. This short id map must be updated when tests
are added or removed. To update the map, execute the following command:

```bash
bundle exec inferno suite lock_short_ids g10_certification
```

Verify that short ids in the file
`./lib/onc_certification_g10_test_kit/g10_certification_short_id_map.yml` are
updated.

**Update Test Procedure Mapping**: The file
`./lib/onc_certification_g10_test_kit/onc_program_procedure.yml` provides a
mapping between the ONC (g)(10) Test Procedure id and the Inferno test short
id. This mapping must be manually updated to ensure that the Inferno tests
align with the (g)(10) test procedure.


**Generate test matrix**: The file './onc_certification_g10_matrix.xlsx'
visually represents the procedure mapping mentioned earlier. After updating the
'onc_program_procedure', execute the following command to update this xlsx
file:
```bash
bundle exec rake g10_test_kit:generate_matrix
```

**Update Terminology**: The ONC (g)(10) Test Kit maintains its own terminology
repository. This terminology should be updated regularly, and whenever a new US
Core test kit is adopted. See the [Terminology Update
Guide](Terminology-Update-Guide.md) for instructions.

**Update Presets**: The `./config/presets/g10_reference_server_preset.json` should
be updated so that values are properly filled for any new version-specific options that
exist. See the existing file for the general format for the preset, as it contains
many examples of how this occurs.

## Step 6. Validate Updates against Reference Server

Prior to publication, all tests should pass against the [Inferno Reference
Server](https://github.com/inferno-framework/inferno-reference-server) to verify
the correctness of the tests against a known good server. This may require
updating [data on the reference
server](https://github.com/inferno-framework/inferno-reference-server-data/),
and in some cases also updating behavior of the reference server. While not
strictly necessary, this is the best way to validate the behavior of the tests,
and is also beneficial to users of the test kit.
