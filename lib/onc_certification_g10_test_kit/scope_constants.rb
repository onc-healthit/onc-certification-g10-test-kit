module ONCCertificationG10TestKit
  module ScopeConstants
    STANDALONE_SMART_2_SCOPES =
      %(
        launch/patient openid fhirUser offline_access patient/Medication.rs
        patient/AllergyIntolerance.rs patient/CarePlan.rs patient/CareTeam.rs
        patient/Condition.rs patient/Coverage.rs patient/Device.rs
        patient/DiagnosticReport.rs patient/DocumentReference.rs
        patient/Encounter.rs patient/Goal.rs patient/Immunization.rs
        patient/Location.rs patient/MedicationDispense.rs
        patient/MedicationRequest.rs patient/Observation.rs
        patient/Organization.rs patient/Patient.rs patient/Practitioner.rs
        patient/PractitionerRole.rs patient/Procedure.rs patient/Provenance.rs
        patient/QuestionnaireResponse.rs patient/RelatedPerson.rs
        patient/ServiceRequest.rs patient/Specimen.rs
      ).gsub(/\s{2,}/, ' ').strip.freeze

    EHR_SMART_2_SCOPES =
      %(
        launch openid fhirUser offline_access user/Medication.rs
        user/AllergyIntolerance.rs user/CarePlan.rs user/CareTeam.rs
        user/Condition.rs user/Coverage.rs user/Device.rs
        user/DiagnosticReport.rs user/DocumentReference.rs user/Encounter.rs
        user/Goal.rs user/Immunization.rs user/Location.rs
        user/MedicationDispense.rs user/MedicationRequest.rs user/Observation.rs
        user/Organization.rs user/Patient.rs user/Practitioner.rs
        user/PractitionerRole.rs user/Procedure.rs user/Provenance.rs
        user/QuestionnaireResponse.rs user/RelatedPerson.rs
        user/ServiceRequest.rs user/Specimen.rs
      ).gsub(/\s{2,}/, ' ').strip.freeze
  end
end
