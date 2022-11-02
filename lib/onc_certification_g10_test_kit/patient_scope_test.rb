module ONCCertificationG10TestKit
  class PatientScopeTest < Inferno::Test
    title 'Patient-level scopes were granted'
    description %(
      Systems are required to support the `permission-patient` capability as
      part of the [Clinician Access for EHR Launch Capability
      Set.](http://hl7.org/fhir/smart-app-launch/1.0.0/conformance/index.html#clinician-access-for-ehr-launch)

      This test verifies that systems are capable of granting patient-level
      scopes during an EHR Launch.
    )
    id :g10_patient_scope
    input :received_scopes

    run do
      expected_scope = if config.options[:scope_version] == :v2
                         'patient/Patient.rs'
                       else
                         'patient/Patient.read'
                       end
      assert received_scopes&.include?(expected_scope),
             "#{expected_scope} scope was requested, but not received. Received: `#{received_scopes}`"
    end
  end
end
