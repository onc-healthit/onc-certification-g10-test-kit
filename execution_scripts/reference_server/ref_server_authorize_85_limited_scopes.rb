gem_dir = Gem::Specification.find_by_name('smart_app_launch_test_kit').gem_dir
load "#{gem_dir}/execution_scripts/reference_server/base_ref_server_authorize.rb"

LIMITED_SCOPES_TO_UNCHECK = ['patient/AllergyIntolerance.rs',
                             'patient/CarePlan.rs',
                             'patient/CareTeam.rs',
                             'patient/Coverage.rs',
                             'patient/Device.rs',
                             'patient/DocumentReference.rs',
                             'patient/DiagnosticReport.rs',
                             'patient/Encounter.rs',
                             'patient/Goal.rs',
                             'patient/Immunization.rs',
                             'patient/Location.rs',
                             'patient/Medication.rs',
                             'patient/MedicationDispense.rs',
                             'patient/MedicationRequest.rs',
                             'patient/Organization.rs',
                             'patient/Practitioner.rs',
                             'patient/PractitionerRole.rs',
                             'patient/Procedure.rs',
                             'patient/Provenance.rs',
                             'patient/QuestionnaireResponse.rs',
                             'patient/RelatedPerson.rs',
                             'patient/ServiceRequest.rs',
                             'patient/Specimen.rs'].freeze

ref_server_authorize(ARGV[0], target_patient_id: '85', click_scopes: LIMITED_SCOPES_TO_UNCHECK)
