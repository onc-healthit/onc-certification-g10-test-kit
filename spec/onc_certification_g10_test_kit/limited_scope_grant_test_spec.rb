require_relative '../../lib/onc_certification_g10_test_kit/limited_scope_grant_test'

RSpec.describe ONCCertificationG10TestKit::LimitedScopeGrantTest do
  let(:test) { described_class }
  let(:suite_id) { 'g10_certification' }

  describe '#scope_granting_access?' do
    def scope_grants_access?(resource_type, scopes)
      test.new.scope_granting_access?(resource_type, scopes)
    end

    it 'does not grant access when a scope starts with a longer resource type prefix' do
      expect(scope_grants_access?('Encounter', ['patient/EncounterDiagnosis.read'])).to be false
    end

    it 'does not grant access when a SMART v2 scope starts with a longer resource type prefix' do
      expect(scope_grants_access?('Encounter', ['patient/EncounterDiagnosis.rs'])).to be false
    end

    it 'does not grant access when a scope has no access level' do
      expect(scope_grants_access?('Encounter', ['patient/Encounter'])).to be false
    end

    it 'grants access when a scope exactly matches the resource type' do
      expect(scope_grants_access?('Encounter', ['patient/Encounter.read'])).to be true
    end

    it 'grants access when a SMART v2 scope exactly matches the resource type' do
      expect(scope_grants_access?('Encounter', ['patient/Encounter.rs'])).to be true
    end

    it 'grants access when a SMART v2 scope with a search parameter matches the resource type' do
      expect(scope_grants_access?('Condition', ['patient/Condition.rs?category=problem-list-item'])).to be true
    end

    it 'grants access when a wildcard scope is present' do
      expect(scope_grants_access?('Encounter', ['patient/*.read'])).to be true
    end

    it 'grants access when a SMART v2 wildcard scope is present' do
      expect(scope_grants_access?('Encounter', ['patient/*.rs'])).to be true
    end

    it 'does not grant access when only a different resource type scope is present' do
      expect(scope_grants_access?('Encounter', ['patient/Patient.read'])).to be false
    end

    it 'does not grant access when the access level is not read or wildcard' do
      expect(scope_grants_access?('Encounter', ['patient/Encounter.write'])).to be false
    end
  end

  describe 'run' do
    [
      ONCCertificationG10TestKit::G10Options::US_CORE_6_REQUIREMENT,
      ONCCertificationG10TestKit::G10Options::US_CORE_7_REQUIREMENT
    ].each do |suite_options|
      context "when using #{suite_options[:us_core_version]}" do
        before do
          allow_any_instance_of(test).to receive(:suite_options).and_return(suite_options)
        end

        it 'passes when a longer resource type prefix scope does not grant a shorter forbidden resource type' do
          result = run(
            test,
            expected_resources: 'Patient',
            received_scopes: 'launch/patient openid patient/EncounterDiagnosis.read patient/Patient.read'
          )

          expect(result.result).to eq('pass')
        end

        it 'fails when a forbidden resource type is granted by an exact scope' do
          result = run(
            test,
            expected_resources: 'Patient',
            received_scopes: 'launch/patient openid patient/Encounter.read patient/Patient.read'
          )

          expect(result.result).to eq('fail')
          expect(result.result_message)
            .to eq('User expected to deny the following resources that were granted: Encounter')
        end

        it 'fails when an expected resource is not granted' do
          result = run(
            test,
            expected_resources: 'Patient, Encounter',
            received_scopes: 'launch/patient openid patient/EncounterDiagnosis.read patient/Patient.read'
          )

          expect(result.result).to eq('fail')
          expect(result.result_message)
            .to eq('User expected to grant access to the following resources: Encounter')
        end

        it 'passes when all expected resources are granted and forbidden resources are denied' do
          result = run(
            test,
            expected_resources: 'Patient',
            received_scopes: 'launch/patient openid patient/Patient.read'
          )

          expect(result.result).to eq('pass')
        end
      end
    end
  end
end
