require_relative '../authorize'

authorize_url = ARGV[0].split('(', 2)[1].split(')').first
GRANULAR_SCOPE_SELECTIONS_TO_CLICK = ['patient/Condition.rs',
                                      'patient/Condition.rs?category=http://hl7.org/fhir/us/core/CodeSystem/condition-category|health-concern',
                                      'patient/Condition.rs?category=http://terminology.hl7.org/CodeSystem/condition-category|encounter-diagnosis',
                                      'patient/Condition.rs?category=http://terminology.hl7.org/CodeSystem/condition-category|problem-list-item',
                                      'patient/Observation.rs',
                                      'patient/Observation.rs?category=http://hl7.org/fhir/us/core/CodeSystem/us-core-category|sdoh',
                                      'patient/Observation.rs?category=http://terminology.hl7.org/CodeSystem/observation-category|social-history',
                                      'patient/Observation.rs?category=http://terminology.hl7.org/CodeSystem/observation-category|laboratory',
                                      'patient/Observation.rs?category=http://terminology.hl7.org/CodeSystem/observation-category|survey',
                                      'patient/Observation.rs?category=http://terminology.hl7.org/CodeSystem/observation-category|vital-signs'].freeze

authorize(authorize_url, target_patient_id: '85', click_scopes: GRANULAR_SCOPE_SELECTIONS_TO_CLICK)
