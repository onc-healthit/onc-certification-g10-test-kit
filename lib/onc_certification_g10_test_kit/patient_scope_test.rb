module ONCCertificationG10TestKit
  class PatientScopeTest < Inferno::Test
    title 'Patient-level scopes were granted'
    description %(
      Systems are required to support the `permission-patient` capability as
      part of the Clinician Access for EHR Launch Capability Set.

      This test verifies that systems are capable of granting patient-level
      scopes during an EHR Launch.

      * [Clinician Access for EHR Launch Capability Set STU
        1](http://hl7.org/fhir/smart-app-launch/1.0.0/conformance/index.html#clinician-access-for-ehr-launch)
      * [Clinician Access for EHR Launch Capability Set STU
        2](http://hl7.org/fhir/smart-app-launch/STU2/conformance.html#clinician-access-for-ehr-launch)
    )
    id :g10_patient_scope
    input :received_scopes

    def scope_version
      config.options[:scope_version]
    end

    run do
      expected_scope = if scope_version == :v2
                         'patient/Patient.rs'
                       else
                         'patient/Patient.read'
                       end
      assert received_scopes&.include?(expected_scope),
             "#{expected_scope} scope was requested, but not received. Received: `#{received_scopes}`"
    end
  end
end
