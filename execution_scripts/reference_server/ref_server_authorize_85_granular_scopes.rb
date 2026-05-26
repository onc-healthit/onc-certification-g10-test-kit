gem_dir = Gem::Specification.find_by_name('smart_app_launch_test_kit').gem_dir
load "#{gem_dir}/execution_scripts/reference_server/base_ref_server_authorize.rb"

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

ref_server_authorize(ARGV[0], target_patient_id: '85', click_scopes: GRANULAR_SCOPE_SELECTIONS_TO_CLICK)
