# 3.8.0

* Update the validator service to version 2.3.0 based on version 6.0.21 of the
  FHIR validation code (#449).
* Minor visual updates.
* Require a Client Secret input for EHR Launch with Patient Scopes (9.8, 9.9)
  tests to be consistent with other SMART App Launch tests (1, 2, 3, 9.4, 9.5,
  9.6, 9.7, 9.8, 9.9).
* Update the version of the SMART App Launch Test Kit (#451). This update will
  add some additional inputs for app launch tests when using SMART App Launch
  2.0.0. These inputs are locked, so no change in behavior is needed when
  running the tests from the UI. If using the JSON API to run tests, however,
  the following new inputs will need to be included in the API calls to create a
  test run:
```
{
  "name": "client_auth_type",
  "value": "confidential_symmetric",
},
{
  "name": "client_auth_encryption_method",
  "value": "ES384",
},
{
  "name": "public_client_auth_type",
  "value": "public",
},
```

# 3.7.2

* Fix an error message which could state that a requested scope is invalid when
  it's actually a received scope which is invalid (#434).

# 3.7.1

* Fix a misleading skip message in the bulk data tests when the next polling
  time is past the maximum allowed time for polling (#426). This message now
  indicates that the next polling time is past the limit, rather than that the
  limit has already passed.

# 3.7.0

* Relax MustSupport requirements for Patient's previous name and previous
  address (#416).

# 3.6.0

* Remove tests for Device UDI-PI presence from US Core 4 & 5 (#404).
* Fix a bug in US Core 4 and 5 which removed
  `MedicationRequest.reportedReference` from the list of Must Support
  references (#412).
* Add tests for the `_since` parameter for Bulk Data v2 (#405).
* Validate that user/patient level scopes are granted in the Standalone Patient
  App and EHR Practition App tests (#333).
* Fix a bug which could prevent the `ServiceRequest.category:us-core` slice from
  being recognized when present in US Core 5 (#406).
* Fix a bug which caused an unhandled exception when a non-FHIR json payload is
  received from a FHIR request (#397).

# 3.5.0

* Update SMART App Launch IG links in EHR Launch with Patient Scopes to point to
  the correct IG versions (#391).
* Add a new test for Bulk Data v2 which checks that polling for the status of a
  cancelled export returns a 404 (#387).
* Suppress missing scope warnings for the Limited App Launch when using SMART
  App Launch STU 2(#393).
* Update preset to support all IG versions (#395).
* Add additional validations that the server advertises support for all required
  resources in its CapabilityStatement (#400).
* Update the version of the FHIR Validator from 5.6.71 to 5.6.93.
* Update the descriptions of the CapabilityStatement group to reflect the
  (g)(10) requirements rather than the base US Core requirements (#402).

# 3.4.0

* Add an attestation that systems are capable of extending the duration of
  refresh tokens (#386).
* Make the patient id list input optional for bulk data. It was previously
  described as optional, but was actually required (#368).
* Update bulk data tests to allow resources to match against multiple resources.
  This is necessary for US Core 5 where a single resource may conform to
  multiple profiles (#378).
* Fix a bug which caused access tokens not to be refreshed when a the token
  refresh response does not contain a new refresh token (#377).
* Update the title and description for Must Support tests (#384).
* Improve the UI for mobile devices.

# 3.3.2

* Fix a bug which causes mime-type codes with a charset to fail terminology
  validation (#370).
* Fix an incorrect error message in the token revocation attestation (#367).
* Fix an issue which prevented Provenance resources from being validated in US
  Core 5 (#366)
* Fix an issue where searches could return resources conforming to multiple
  profiles in US Core 5 (#356).
* Fix a bug which prevents health concern Conditions from being identified in
  Bulk Data responses for US Core 5 (#372).
* Allow Media scopes to be requested when using US Core 5 (#375).
* Update the UI to display in-progress icons for running/queued tests.
* Update the UI to automatically open groups with a skip result.
* Change the display for ingoing/outgoing requests in the UI.
* Remove the copy button and url truncation from print view.

# 3.3.1

* Fix a bug related to validating slices with required bindings which prevented
  US Core 5 Problems and Health Concerns from being validated (#340).
* Update terminology build to work with Ruby 3 (#342).

# 3.3.0

* Update the version of the FHIR Validator from 5.6.21 to 5.6.71.
* Fix a bug where the EHR Launch with Patient Scopes tests were not verifying
  that patient-level scopes were received.
* Fix a bug which prevented Clinical Test Observations from beind identified in
  bulk data tests for US Core 5.
* Fix a bug which prevented terminology from being validated.
* Fix a bug which related to search parameter values which contain commas.
* Fix a bug which prevented MustSupport slices based on a required binding from
  being recognized in Must Support tests for US Core 5.
* Remove DocumentReference.custodian from MustSupport tests for US Core 3.1.1.
* Remove permission-v1 from the list of required capabilities for SMART App
  Launch V2.
* Fix a bug which could cause the screen to rapidly flicker on the suite
  selection page at certain screen sizes.
  
# 3.2.0

* Fix a bug which could cause unhandled exceptions when invalid JSON is
  received.
* Fix a bug which prevented handing the Imaging Result profile in the Bulk Data
  tests when using US Core 5.
* Update the terminology process to only use the most recent version of UMLS.
* Update the TLS tests to allow systems which deny prohibited TLS versions at
  the application level to pass.
* Fix MustSupport requirements for representing a Patient's previous name in US
  Core 4 & 5.
* Fix date comparator searches to account for server time zones.
* Update the SMART App Launch tests to handle relative urls.

# 3.1.0

* Fix a bug which could cause the SMART `context-ehr-encounter` capability to be
  required when testing against USCDI v1.
* Fix a bug which caused head circumference resources to be validated in the
  bulk data tests when using US Core 3.
* Fix a typo in the US Core 5 Single Patient API group description.
* Fix a bug which caused the `_outputFormat` param to not be url encoded.
* Fix an unhandled exception in the SMART discovery group when `rest.security`
  is not present.
* Fix a bug which could cause inconsistent validation results between the single
  patient and multi patient tests.
* Fix a typo when no resources are found.
* Prevent validation errors from appearing on reference resolution tests.
* Fix a nil-safety issue in reference resolution tests.
* Remove QuestionnaireResponse from the list of Must Support target profiles for
  US Core Observation Survey and US Core SDOH Assessment (US Core 5).
* Fix a bug which incorrectly marked SmokingStatus searches by patient +
  category + date as optional (US Core 4 & 5).
* Add tests to verify that servers correctly reject token refresh requests with
  invalid refresh tokens.
* Add an attestation test for demonstrating the public location of base urls.
* Minor UI updates.

# 3.0.1

* Use new version of Inferno Core which fixes performance issue when running the
  entire test suite.
* Fix the input order for the SMART 1.0.0 EHR Launch with Patient Scopes.

# 3.0.0

* Add tests for US Core 4.0.0, US Core 5.0.1, SMART App Launch 2.0.0, and Bulk
  Data 2.0.0.
* Update the terminology build process for US Core 4.0.0 and 5.0.1.
* Update the resource validation tests to include the profile version in
  validation calls.
* Add tests for EHR Launch with patient scopes.
* Fix a bug where terminology errors from the FHIR validator service were not
  being excluded.

# 2.3.0

* Add feature flags to support planned SVAP updates.
* Allow custom bulk data JWKS.
* Set Limited App Launch test to use same inputs as Standalone Patient App Launch test.
* Remove warning on Limited App Launch test for "missing" scopes.
* Fix hard coded resource type in resource access test.
* Add README reference to PostgreSQL installation for mult-user deployments.
* Customize footer links for downloading and issue reporting.
* Add IE11 instructions for EHR Launches.

# 2.2.2

* Remove invalid launch parameter tests.

# 2.2.1

* Update JWK Set response while acting as a Backend Services client in
  the Multi-Patient API tests to not include corresponding private keys.
* Update JWK Set response to include `application/json` Content-Type header.

# 2.2.0

* Update Bulk Data Export validation test to continue validating all returned 
  resources even after encountering an invalid one. It now reports total number 
  of invalid resources and their line number.
* Add configuration error message when using a development version, and not an 
  official release. 
* Update omit message in Bulk Data Export tests when no Medication/Location 
  resources are returned to explicitly state that they are not required.
* Fix EHR Launch capabilities check, which were incorrectly verifying
  against Standalone capabilities.
* Update links in Bulk Data group to v1.0.1 of Bulk Data rather than v1.0.0.
* Validate `sub` field in OpenID Connect tests.
* Limit Clinical Notes Guidance attachment tests to specific DiagnosticReport
  types.
* Update to inferno-core v0.3.2, which includes a number of UI and failure 
  message improvements.

# 2.1.1

* Fix a bug caused by leaving the 'Additional Patient IDs' input in the
  Single Patient API group empty.
  
# 2.1.0

* Update patient ID inputs from a single list of patient IDs to the patient ID
  from a SMART launch plus a list of additional patient IDs.
* Add missing `Accept` header to test `5.2.05`.
* Fix a bug which caused the terminology build to run in `development` rather
  than `production` mode, causing it to be unable to see the database created by
  `setup.sh`.
* Add terminologies based on `BCP 47` (used to represent human languages) to the
  set of terminologies with relaxed checks on the total number of codes.
* Fix a bug with the terminology build caused by not having a `tmp` folder.
* Update Bulk Data file download tests to follow redirects. Inferno will not
  include an `Authorization` header when following a redirect for a bulk data
  file download.
* Fix a bug where some terminology messages from the FHIR validator were not
  being excluded.
* Update the title and description of Visual Inspection and Attestation test
  `6.6.05`.
* Update the input forms to display inputs in a more reasonable order and fix
  incorrect input titles.
* Relax the requirements for advertising support for the `Group/[id]/$export`
  Operation in a server's CapabilityStatement. This test will now pass if any
  Group Operations are listed, and warnings will be displayed if no Operation is
  declared at `Group/[id]/$export` or if the Operation has a url other than the
  url of the Operation defined in the Bulk Data IG. An additional warning will
  be displayed if the server does not declare that it instantiates the Bulk Data
  IG.
* Fix a bug with the bulk data group export validation tests where tests would
  fail if all Must Support fields were not present in a single export file.
* Update US Core Test Kit from `v0.1.1` to `v0.2.1`:
  * Reference resolution tests now only check Must Support references
  * Reference resolution tests now requests and display them in the UI
  * Reference resolution tests removed for profiles with no Must Support
    references
  * Fix a string interpolation bug in reference search checks.
  * Fix a bug in the error message for mismatched ids in read tests.
* Update SMART App Launch Test Kit from `v0.1.1` to `v0.1.2`:
  * Update scope validation for taken refresh to accept a subset of the
    originally granted scopes.
  * Lengthen PKCE code verifier to match spec.
* Update Inferno Core from `v0.2.0` to `v0.3.0`
  * Various minor UI improvements
  * Improve how inputs are handled in the backend so that the UI can display
    inputs exactly as received from the JSON api rather than needing to
    determine that itself.
  * Add the ability to specify the order in which inputs appear in the UI.
  * Add the ability to copy/paste JSON/YAML versions of inputs in the UI.
  * Update the preset input selection UI.
  * Add an inputs/outputs to test and report displays in the UI.
  * Add the ability to display a custom banner at the top of the page.
  * Update the UI for suite configuration messages. Info and warning messages
    will now be displayed in addition to error messages.
  * Update the UI to not omit required indicators from locked inputs.
  * Fix a bug where sometimes in an input would appear twice in the UI.
  * Fix a bug where the *New Session* button was using the wrong url.
  * Fix a bug where primitive extensions were stripped from resources before
    they were validated.
  * Fix a bug where a test run could be created without all of the required
    inputs.

# 2.0.0

Initial public release

# 2.0.0.rc3

* Fix links in invalid aud & invalid launch groups.

# 2.0.0.rc2

* Fix terminology build.
* Add invalid launch group.
* Omit bulk data tests for Medication and Location if no resources are
  available.
* Update SMART App Launch and Bulk Data IG links.

# 2.0.0.rc1

Initial release candidate
