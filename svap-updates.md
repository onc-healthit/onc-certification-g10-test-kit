## US Core 4.0.0
* Single Patient and Multi-Patient API tests now validate against US Core 4.0.0
  profiles.
* Tests 9.10.11 and 9.10.12, Attestations for Patient Demographics Suffix and
  Previous Name USCDI v1 elements were removed. These elements are now checked
  in an automated fashion in the Patient Must Support test (5.2.09).
* New test groups for BMI and Head Circumference were added to the Single
  Patient API tests (5.16, 5.17).
* Multi-Patient API Observation tests now check for the presence of BMI and Head
  Circumference resources (7.3.16). TODO: add bulk data 2 number
  
## US Core 5.0.1
* Single Patient and Multi-Patient API tests now validate against US Core 5.0.1
  profiles.
* Standalone and EHR Launch groups now check that scopes have been granted to
  access ServiceRequest resources, and allow QuestionnaireResponse scopes to be
  granted (1.3.08, 3.3.10). TODO: add SMART v2
* Encounter and ServiceRequest were added to the list of required resources in
  the Unrestricted Resource Type Access group (1.7). TODO: add SMART v2
* Encounter and ServiceRequest were added to the list of resources checked in
  the Limited Access App group (2). TODO: add SMART v2
* The SMART `context-ehr-encounter` capability is now required for EHR
  Practitioner App (3.1.05). TODO: add SMART v2
* New test to retrieve the in-context Encounter added to the EHR Practitioner
  App tests (3.3.13). TODO: smart v2
* Tests 9.10.11 and 9.10.12, Attestations for Patient Demographics Suffix and
  Previous Name USCDI v1 elements are removed. These elements are now checked in
  an automated fashion in the Patient Must Support test (6.2.09).
* Single Patient API Condition tests replaced with Condition Encounter Diagnosis
  and Condition Problems and Health Concerns Tests (6.6, 6.7).
* Single Patient API tests for the following Observation profiles were added:
  Head Circumference, BMI, Clinical Test Result, Sexual Orientation, Social
  History, Imaging Result, and SDOH Assessment (6.17, 6.19, 6.25, 6.26, 6.31).
* Test groups for ServiceRequest, RelatedPerson, QuestionnaireResponse, and
  PractitionerRole were added to Multi-Patient API test group. TODO: bulk v2
* Multi-Patient API Condition tests now check for the the presence of Encounter
  Diagnosis, and Problems and Health Concerns resources (7.3.09). TODO: bulk v2
* Multi-Patient API Observation tests now check for the presence of Head
  Circumference, BMI, Clinical Test Result, Sexual Orientation, Social History,
  and SDOH Assessment profiles (7.3.16). TODO: bulk v2

## SMART App Launch 2.0.0
* The SMART on FHIR Discovery Group no longer checks the server's
  CapabilityStatement.
* The following fields are now required to be present in the server's well-known
  configuration: `issuer`, `jwks_uri`, `grant_types_supported`,
  `code_challenge_methods_supported`.
* All SMART launches are required to use PKCE with the S256 code challenge
  method.
* The Patient Standalone App and EHR Practitioner App groups now require that
  v2-style scopes are used.
* The Patient Standalone App and EHR Practitioner App groups now require servers
  to support the `authorize-post`, `permission-v1`, and `permission-v2`
  capabilities.
* The EHR Practitioner App launch uses HTTP POST to test the `authorize-post`
  capability.

## Bulk Data 2.0.0
* Added a test to check that the server supports the `_outputFormat` parameter.
