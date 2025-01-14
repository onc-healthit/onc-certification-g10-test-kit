require_relative '../../lib/onc_certification_g10_test_kit/smart_standalone_patient_app_group'

RSpec.describe ONCCertificationG10TestKit::SmartEHRPractitionerAppGroup do
  it 'has a properly configured SMART v1 auth input' do
    inputs =
      described_class.available_inputs(
        [Inferno::DSL::SuiteOption.new(id: :smart_app_launch_version, value: 'smart_app_launch_1')]
      )

    auth_input = inputs[:ehr_smart_auth_info]

    expected_auth_input_options =
      {
        mode: 'auth',
        components: [
          {
            name: :auth_type,
            default: 'symmetric',
            options: {
              list_options: [
                { label: 'Public', value: 'public' },
                { label: 'Confidential Symmetric', value: 'symmetric' }
              ]
            },
            locked: true
          },
          {
            name: :requested_scopes,
            type: 'textarea',
            default: 'launch openid fhirUser offline_access user/Medication.read user/AllergyIntolerance.read user/CarePlan.read user/CareTeam.read user/Condition.read user/Device.read user/DiagnosticReport.read user/DocumentReference.read user/Encounter.read user/Goal.read user/Immunization.read user/Location.read user/MedicationRequest.read user/Observation.read user/Organization.read user/Patient.read user/Practitioner.read user/Procedure.read user/Provenance.read user/PractitionerRole.read'
          },
          { name: :auth_request_method, default: 'POST', locked: true },
          { name: :use_discovery, locked: true }
        ]
      }

    expect(auth_input.options[:components]).to match_array(expected_auth_input_options[:components])
  end

  it 'has a properly configured SMART v2 auth input' do
    inputs =
      described_class.available_inputs(
        [Inferno::DSL::SuiteOption.new(id: :smart_app_launch_version, value: 'smart_app_launch_2')]
      )

    auth_input = inputs[:ehr_smart_auth_info]

    expected_auth_input_options =
      {
        mode: 'auth',
        components: [
          {
            name: :auth_type,
            default: 'symmetric',
            options: {
              list_options: [
                { label: 'Public', value: 'public' },
                { label: 'Confidential Symmetric', value: 'symmetric' },
                { label: 'Confidential Asymmetric', value: 'asymmetric' },
                { label: 'Backend Services', value: 'backend_services' }
              ]
            },
            locked: true
          },
          {
            name: :requested_scopes,
            type: 'textarea',
            default: 'launch openid fhirUser offline_access user/Medication.rs user/AllergyIntolerance.rs user/CarePlan.rs user/CareTeam.rs user/Condition.rs user/Device.rs user/DiagnosticReport.rs user/DocumentReference.rs user/Encounter.rs user/Goal.rs user/Immunization.rs user/Location.rs user/MedicationRequest.rs user/Observation.rs user/Organization.rs user/Patient.rs user/Practitioner.rs user/Procedure.rs user/Provenance.rs user/PractitionerRole.rs'
          },
          { name: :auth_request_method, default: 'POST', locked: true },
          { name: :use_discovery, locked: true },
          { name: :pkce_support, default: 'enabled', locked: true },
          { name: :pkce_code_challenge_method, default: 'S256', locked: true }
        ]
      }

    expect(auth_input.options[:components]).to match_array(expected_auth_input_options[:components])
  end

  it 'has a properly configured SMART v2.2 auth input' do
    inputs =
      described_class.available_inputs(
        [Inferno::DSL::SuiteOption.new(id: :smart_app_launch_version, value: 'smart_app_launch_2_2')]
      )

    auth_input = inputs[:ehr_smart_auth_info]

    expected_auth_input_options =
      {
        mode: 'auth',
        components: [
          {
            name: :auth_type,
            default: 'symmetric',
            options: {
              list_options: [
                { label: 'Public', value: 'public' },
                { label: 'Confidential Symmetric', value: 'symmetric' },
                { label: 'Confidential Asymmetric', value: 'asymmetric' },
                { label: 'Backend Services', value: 'backend_services' }
              ]
            },
            locked: true
          },
          {
            name: :requested_scopes,
            type: 'textarea',
            default: 'launch openid fhirUser offline_access user/Medication.rs user/AllergyIntolerance.rs user/CarePlan.rs user/CareTeam.rs user/Condition.rs user/Device.rs user/DiagnosticReport.rs user/DocumentReference.rs user/Encounter.rs user/Goal.rs user/Immunization.rs user/Location.rs user/MedicationRequest.rs user/Observation.rs user/Organization.rs user/Patient.rs user/Practitioner.rs user/Procedure.rs user/Provenance.rs user/PractitionerRole.rs'
          },
          { name: :auth_request_method, default: 'POST', locked: true },
          { name: :use_discovery, locked: true },
          { name: :pkce_support, default: 'enabled', locked: true },
          { name: :pkce_code_challenge_method, default: 'S256', locked: true }
        ]
      }

    expect(auth_input.options[:components]).to match_array(expected_auth_input_options[:components])
  end
end
