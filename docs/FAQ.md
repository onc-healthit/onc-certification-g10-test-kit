The following is a list of commonly asked questions from users of the Test Kit.

### How does Inferno test US Core Encounter resource?
The Inferno Encounter test is only concerned with references to Encounter
resources that it knows MUST support the US Core Encounter profile.  Not all
references to Encounter resources within other US Core profiles need to conform
to the US Core Encounter profile. For an example of a reference to `Reference(US
Core Encounter)`, see [US Core DiagnosticReport
Note](http://hl7.org/fhir/us/core/STU3.1.1/StructureDefinition-us-core-diagnosticreport-note.html)'s
`encounter` element. [US Core
DocumentReference](http://hl7.org/fhir/us/core/STU3.1.1/StructureDefinition-us-core-documentreference.html)'s
`context.encounter` is another example. If you populate these elements with
encounter references, you should start getting references that are tested in the
Encounter test. Note: US Core has two profiles for DiagnosticReport. Only the
DiagnosticReport Note profile mentioned above has US Core Encounter reference.
The other profile (US Core DiagnosticReport Lab Result) does NOT have US Core
Encounter reference.

### Q: How does Inferno test US Core Organization resource?
Similar to the Encounter test, the Inferno Organization test is only concerned with
references to Organization resources that it knows MUST support the US Core
Organization profile. Here is a list of elements having reference to
`Reference(US Core Organization)` in US Core v3.1.1:
* CareTeam.participant.member
* DiagnosticReport.performer
* DocumentReference.author
* MedicationRequest.requester
* Provenance.agent.who
* Provenance.agent.onBehalfOf

### Q: What is the difference between "skipped" test and "omitted" test?
Inferno has four states for test results:
| State | Meaning |
|---|---|
| Pass | Server response is valid for this test. |
| Omit | This test does not apply to the server due to server configuration. The pass or fail of a test sequence is not affected by omitted test. |
| Skip | Server response does not contain all necessary information, and Inferno can NOT complete the test to verify the server's behavior. Tester should provide additional data to continue the test. A test sequence is treated as failed if there is skipped test. |
| Fail | Server response is NOT valid for this test. |

### Q: How does Inferno test MustSupport flag on an element?
Inferno follows guidance provided by [HL7 FHIR Conformance
Rules](https://www.hl7.org/fhir/conformance-rules.html#mustSupport) and [US Core
IG General
Guidance](http://hl7.org/fhir/us/core/STU3.1.1/general-guidance.html#must-support).
Inferno checks that a server implementation SHALL demonstrate that it supports
the "MustSupport" element in a meaningful way. In general, Inferno "MustSupport"
tests check that each "MustSupport" element is present in at least one resource
from all resources returned from the server. It is not necessary that one
resource contain all MustSupport elements. Inferno does not consider using a
"Data Absent Reason" (DAR) extension on a "MustSupport" element as supporting
the element "in a meaningful way," so Inferno ignores elements with DAR
extensions when looking for "MustSupport" elements.

### Q: Why do some resources fail in US Core Test Kit with terminology validation errors?
US Core Test Suite depends on [tx.fhir.org](http://tx.fhir.org/r4/) to do the
terminology validation. This terminology server is not maintained by Inferno. If
you get a terminology validation error in US Core Test Suite, please check the
code against the corresponding US Core value set. If you are certain the code is
correct, please report the issue to the [Inferno
Repository](https://github.com/onc-healthit/onc-certification-g10-test-kit/issues).
We will investigate the root cause of the terminology failure. If it is determined that
the error is on the terminology server, we will report the issue to the [terminology
stream on Zulip](https://chat.fhir.org/#narrow/stream/179202-terminology).
