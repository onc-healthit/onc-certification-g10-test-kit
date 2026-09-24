require_relative '../../lib/onc_certification_g10_test_kit/unrestricted_resource_type_access_group'

RSpec.describe ONCCertificationG10TestKit::UnrestrictedResourceTypeAccessGroup do
  let(:group) { described_class }
  let(:suite_id) { 'g10_certification' }
  let(:scope_test) do
    group.tests.find { |test| test.title == 'Scope granted enables access to all US Core resource types.' }
  end
  let(:smart_auth_info) { Inferno::DSL::AuthInfo.new(access_token: 'ACCESS_TOKEN') }

  {
    ONCCertificationG10TestKit::G10Options::US_CORE_6_REQUIREMENT =>
      ONCCertificationG10TestKit::AllResources::V6_ALL_RESOURCES - described_class::V6_EXCLUDED_RESOURCES,
    ONCCertificationG10TestKit::G10Options::US_CORE_7_REQUIREMENT =>
      ONCCertificationG10TestKit::AllResources::V7_ALL_RESOURCES - described_class::V7_EXCLUDED_RESOURCES
  }.each do |suite_options, required_resources|
    context "when using #{suite_options[:us_core_version]}" do
      before do
        allow_any_instance_of(scope_test).to receive(:suite_options).and_return(suite_options)
      end

      describe 'scope granted enables access to all US Core resource types' do
        def scope_grants_access?(resource_type, scopes)
          scope_test.new.tap do |test|
            allow(test).to receive(:received_scopes).and_return(scopes.join(' '))
          end.scope_granting_access?(resource_type)
        end

        it 'does not grant access when a scope starts with a longer resource type prefix' do
          expect(scope_grants_access?('Encounter', ['patient/EncounterDiagnosis.read'])).to be false
        end

        it 'does not grant access when a SMART v2 scope starts with a longer resource type prefix' do
          expect(scope_grants_access?('Encounter', ['patient/EncounterDiagnosis.rs'])).to be false
        end

        it 'does not grant access when a user-level scope starts with a longer resource type prefix' do
          expect(scope_grants_access?('ServiceRequest', ['user/ServiceRequestGroup.read'])).to be false
        end

        it 'grants access when a scope exactly matches the resource type' do
          expect(scope_grants_access?('Encounter', ['patient/Encounter.read'])).to be true
        end

        it 'grants access when a SMART v2 scope exactly matches the resource type' do
          expect(scope_grants_access?('Encounter', ['patient/Encounter.rs'])).to be true
        end

        it 'grants access when a wildcard scope is present' do
          expect(scope_grants_access?('Encounter', ['patient/*.read'])).to be true
        end

        it 'grants access to non-patient compartment resources with user-level scopes' do
          expect(scope_grants_access?('ServiceRequest', ['user/ServiceRequest.read'])).to be true
        end

        it 'grants access to non-patient compartment resources with user-level wildcard scopes' do
          expect(scope_grants_access?('ServiceRequest', ['user/*.read'])).to be true
        end

        it 'does not grant access to patient compartment resources with user-level scopes' do
          expect(scope_grants_access?('Encounter', ['user/Encounter.read'])).to be false
        end

        it 'passes when a wildcard scope grants access to all resources' do
          result = run(
            scope_test,
            url: 'http://example.com/fhir',
            patient_id: '123',
            received_scopes: 'launch/patient openid patient/*.read',
            smart_auth_info:
          )

          expect(result.result).to eq('pass')
        end

        it 'passes when every required resource type is granted by an exact scope' do
          scopes = required_resources.map { |resource_type| "patient/#{resource_type}.read" }

          result = run(
            scope_test,
            url: 'http://example.com/fhir',
            patient_id: '123',
            received_scopes: "launch/patient openid #{scopes.join(' ')}",
            smart_auth_info:
          )

          expect(result.result).to eq('pass')
        end

        it 'fails when Encounter is only covered by a scope for a longer resource type prefix' do
          scopes = (required_resources - ['Encounter']).map { |resource_type| "patient/#{resource_type}.read" }

          result = run(
            scope_test,
            url: 'http://example.com/fhir',
            patient_id: '123',
            received_scopes: "launch/patient openid #{scopes.join(' ')} patient/EncounterDiagnosis.read",
            smart_auth_info:
          )

          expect(result.result).to eq('fail')
          expect(result.result_message).to include('does not grant access to the `Encounter` resource')
        end
      end
    end
  end
end
