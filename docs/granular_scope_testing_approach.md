# SMART App Launch 2.0 Fine-Grained Scopes Testing Approach

## Regulatory Background

[HTI-1 fine-grained scopes regulation
text](https://www.federalregister.gov/d/2023-28857/p-1245)

> Health IT Modules certified to § 170.315(g)(10) must minimally be capable of
  handling finer-grained scopes using the “category” parameter for (1) the
  Condition resource with Condition sub-resources Encounter Diagnosis, Problem
  List, and Health Concern and (2) the Observation resource with Observation
  sub-resources Clinical Test, Laboratory, Social History, SDOH, Survey, and
  Vital Signs.

### Required Scopes

* Condition
  * Encounter Diagnosis
    `Condition.rs?category=http://terminology.hl7.org/CodeSystem/condition-category|encounter-diagnosis`
  * Problem List
    `Condition.rs?category=http://terminology.hl7.org/CodeSystem/condition-category|problem-list-item`
  * Health Concern
    `Condition.rs?category=http://hl7.org/fhir/us/core/CodeSystem/condition-category|health-concern`
* Observation
  * Clinical Test
    `Observation.rs?category=http://terminology.hl7.org/CodeSystem/observation-category|procedure`
  * Laboratory
    `Observation.rs?category=http://terminology.hl7.org/CodeSystem/observation-category|laboratory`
  * Social History
    `Observation.rs?category=http://terminology.hl7.org/CodeSystem/observation-category|social-history`
  * SDOH
    `Observation.rs?category=http://hl7.org/fhir/us/core/CodeSystem/us-core-category|sdoh`
  * Survey
    `Observation.rs?category=http://terminology.hl7.org/CodeSystem/observation-category|survey`
  * Vital Signs
    `Observation.rs?category=http://terminology.hl7.org/CodeSystem/observation-category|vital-signs`

## Testing Goals

* Verify that systems can grant required fine-grained scopes
* Verify that systems correctly filter returned resources based on the granted
  fine-grained scopes
* Balance thoroughness and testing burden
  
## Testing Requirements

* The same user and patient context is used for all scenarios
* The expected fine-grained scopes are granted
* Resources which do not match the fine-grained scope are not received
* All resources which match the scope and were received when using
  resource-level scopes are received
* No resources are received which were not received when using resource-level
  scopes

## Testing Approach

* Split the fine-grained scopes into two groups
  * Testing all granular scopes at once would not allow to adequately
    demonstrate that the server does not return resources which do not match the
    granted scopes
  * Testing all granular scopes individually would create too large of a burden
    on testers (a minimum of 6 launches/registrations for US Core 6, and 8 for
    US Core 7)
  * Two groups of scopes will allow Inferno to verify that resources not
    matching the scopes are not returned while minimizing the number of app
    registrations/launches
* For each group of scopes, compare the resources returned when using
  fine-grained scopes to those returned when using resource-level scopes

### Scope Groups

#### US Core 6.1.0 (HTI-1)

* Group 1
  * `Condition.rs?category=http://terminology.hl7.org/CodeSystem/condition-category|encounter-diagnosis`
  * `Observation.rs?category=http://terminology.hl7.org/CodeSystem/observation-category|laboratory`
  * `Observation.rs?category=http://terminology.hl7.org/CodeSystem/observation-category|social-history`
  * `Observation.rs?category=http://terminology.hl7.org/CodeSystem/observation-category|procedure`
* Group 2
  * `Condition.rs?category=http://hl7.org/fhir/us/core/CodeSystem/condition-category|health-concern`
  * `Condition.rs?category=http://terminology.hl7.org/CodeSystem/condition-category|problem-list-item`
  * `Observation.rs?category=http://terminology.hl7.org/CodeSystem/observation-category|vital-signs`
  * `Observation.rs?category=http://terminology.hl7.org/CodeSystem/observation-category|survey`
  * `Observation.rs?category=http://hl7.org/fhir/us/core/CodeSystem/us-core-category|sdoh`

#### US Core 7.0.0

* Group 1
  * `Condition.rs?category=http://terminology.hl7.org/CodeSystem/condition-category|encounter-diagnosis`
  * `Condition.rs?category=http://hl7.org/fhir/us/core/CodeSystem/condition-category|health-concern`
  * `DiagnosticReport.rs?category=http://loinc.org|LP29684-5`
  * `DiagnosticReport.rs?category=http://loinc.org|LP29708-2`
  * `DocumentReference.rs?category=http://hl7.org/fhir/us/core/CodeSystem/us-core-documentreference-category|clinical-note`
  * `Observation.rs?category=http://terminology.hl7.org/CodeSystem/observation-category|laboratory`
  * `Observation.rs?category=http://terminology.hl7.org/CodeSystem/observation-category|social-history`
  * `Observation.rs?category=http://terminology.hl7.org/CodeSystem/observation-category|imaging`
  * `Observation.rs?category=http://terminology.hl7.org/CodeSystem/observation-category|procedure`
  * `ServiceRequest.rs?category=http://hl7.org/fhir/us/core/CodeSystem/us-core-category|sdoh`
* Group 2
  * `Condition.rs?category=http://terminology.hl7.org/CodeSystem/condition-category|problem-list-item`
  * `DiagnosticReport.rs?category=http://loinc.org|LP7839-6`
  * `DiagnosticReport.rs?category=http://terminology.hl7.org/CodeSystem/v2-0074|LAB`
  * `Observation.rs?category=http://terminology.hl7.org/CodeSystem/observation-category|vital-signs`
  * `Observation.rs?category=http://hl7.org/fhir/us/core/CodeSystem/us-core-category|treatment-intervention-prefer  * ence`
  * `Observation.rs?category=http://hl7.org/fhir/us/core/CodeSystem/us-core-category|care-experience-preference`
  * `Observation.rs?category=http://terminology.hl7.org/CodeSystem/observation-category|survey`
  * `ServiceRequest.rs?category=http://hl7.org/fhir/us/core/CodeSystem/us-core-category|functional-status`
  * `ServiceRequest.rs?category=http://snomed.info/sct|387713003`

### Testing Workflow
* Perform a SMART App Launch with resource-level scopes
* Perform US Core FHIR API tests with resource-level scopes
  * Tag search requests for resources with fine-grained scopes with their
    resource type and search parameters, e.g. a request for
    `Condition?category=encounter-diagnosis&patient=85` would be tagged with
    `Condition?category&patient`
* Split the fine-grained scopes into two groups, and for each:
  * Perform a SMART App Launch with one subset of fine-grained scopes
    * **TODO:** Verify granted scopes and user/patient context 
  * For every set of search parameters for resources with fine-grained scope
    requirements:
    * Load all the requests made with those search parameters based on the tags
      above, and repeat those searches
    * Verify that the results:
      * Include no resources which do not match the granted scopes
      * Include all resources from the original request which do match the
        granted scopes
      * Do not include any resources which were not present in the original
        request
  * **TODO:** Perform FHIR reads for resources which do and do not match the
    granted scopes, and verify that only resources which match are returned
