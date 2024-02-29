RSpec.describe 'Resource Validation' do # rubocop:disable RSpec/DescribeClass
  let(:resource) { FHIR.from_contents('{"resourceType": "Immunization", "id": "123"}') }

  def reset_g10_validators(use_hl7_resource_validator)
    ONCCertificationG10TestKit::G10CertificationSuite.fhir_validators[:default].clear

    ENV['USE_HL7_RESOURCE_VALIDATOR'] = use_hl7_resource_validator.to_s

    [
      ONCCertificationG10TestKit::G10Options::US_CORE_3_REQUIREMENT,
      ONCCertificationG10TestKit::G10Options::US_CORE_4_REQUIREMENT,
      ONCCertificationG10TestKit::G10Options::US_CORE_5_REQUIREMENT,
      ONCCertificationG10TestKit::G10Options::US_CORE_6_REQUIREMENT

    ].each do |us_core_version_requirement|
      ONCCertificationG10TestKit::G10CertificationSuite.setup_validator(us_core_version_requirement)
    end
  end

  describe 'with Inferno validator wrapper' do
    before do
      reset_g10_validators(false)
    end

    let(:runnable) { ONCCertificationG10TestKit::G10CertificationSuite.groups.first.groups.first.tests.first.new }
    let(:validator_url) { runnable.find_validator(:default).url }
    let(:operation_outcome_string1) do
      File.read(File.join(__dir__, '..', 'fixtures', 'OperationOutcome-code-invalid-1.json'))
    end
    let(:operation_outcome_string2) do
      File.read(File.join(__dir__, '..', 'fixtures', 'OperationOutcome-code-invalid-2.json'))
    end

    it 'excludes Unknown Code messages' do
      stub_request(:post, "#{validator_url}/validate?profile=PROFILE")
        .to_return(status: 200, body: operation_outcome_string1)

      expect(runnable.resource_is_valid?(resource:, profile_url: 'PROFILE')).to be(true)
      expect(runnable.messages.length).to be_zero
    end

    it 'excludes CodeableConcept not in VS messages' do
      stub_request(:post, "#{validator_url}/validate?profile=PROFILE")
        .to_return(status: 200, body: operation_outcome_string2)

      expect(runnable.resource_is_valid?(resource:, profile_url: 'PROFILE')).to be(true)
      expect(runnable.messages.length).to be_zero
    end

    it 'excludes Coding not in VS messages' do
      oo = FHIR::OperationOutcome.new(
        issue: [
          {
            severity: 'error',
            code: 'code-invalid',
            details: {
              text: 'The Coding provided (urn:oid:2.16.840.1.113883.6.238#2106-3) is not in the value set ' \
                    'http://hl7.org/fhir/us/core/ValueSet/omb-race-category, and a code is required from ' \
                    'this value set. (error message = Not in value set ' \
                    'http://hl7.org/fhir/us/core/ValueSet/omb-race-category)'
            },
            expression: [
              'Patient.extension[0].extension[0].value.ofType(Coding)'
            ]
          }
        ]
      )
      stub_request(:post, "#{validator_url}/validate?profile=PROFILE")
        .to_return(status: 200, body: oo.to_json)

      expect(runnable.resource_is_valid?(resource:, profile_url: 'PROFILE')).to be(true)
      expect(runnable.messages.length).to be_zero
    end
  end

  describe 'with HL7 validator wrapper' do
    before do
      reset_g10_validators(true)
    end

    let(:runnable) { ONCCertificationG10TestKit::G10CertificationSuite.groups.first.groups.first.tests.first.new }
    let(:validator_url) { runnable.find_validator(:default).url }
    let(:validation_response_string1) do
      File.read(File.join(__dir__, '..', 'fixtures', 'ValidationResponse-code-invalid-1.json'))
    end
    let(:validation_response_string2) do
      File.read(File.join(__dir__, '..', 'fixtures', 'ValidationResponse-code-invalid-2.json'))
    end
    let(:validation_response_string3) do
      File.read(File.join(__dir__, '..', 'fixtures', 'ValidationResponse-code-invalid-3.json'))
    end

    it 'excludes Unknown Code messages' do
      stub_request(:post, "#{validator_url}/validate")
        .to_return(status: 200, body: validation_response_string1)

      expect(runnable.resource_is_valid?(resource:, profile_url: 'PROFILE')).to be(true)
      expect(runnable.messages.length).to be_zero
    end

    it 'excludes CodeableConcept not in VS messages' do
      stub_request(:post, "#{validator_url}/validate")
        .to_return(status: 200, body: validation_response_string2)

      expect(runnable.resource_is_valid?(resource:, profile_url: 'PROFILE')).to be(true)
      expect(runnable.messages.length).to be_zero
    end

    it 'excludes Coding not in VS messages' do
      stub_request(:post, "#{validator_url}/validate")
        .to_return(status: 200, body: validation_response_string3)

      expect(runnable.resource_is_valid?(resource:, profile_url: 'PROFILE')).to be(true)
      expect(runnable.messages.length).to be_zero
    end
  end
end
