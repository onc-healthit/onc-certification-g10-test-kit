require_relative '../authorize'

authorize_url = ARGV[0].split('(', 2)[1].split(')').first
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

authorize(authorize_url, target_patient_id: '85', click_scopes: LIMITED_SCOPES_TO_UNCHECK)
