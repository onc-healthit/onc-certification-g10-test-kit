RSpec.describe 'Resource Validation' do # rubocop:disable RSpec/DescribeClass
  let(:resource) { FHIR.from_contents('{"resourceType": "Immunization", "id": "123"}') }

  def reset_g10_validators
    ONCCertificationG10TestKit::G10CertificationSuite.fhir_validators[:default].clear

    [
      ONCCertificationG10TestKit::G10Options::US_CORE_3_REQUIREMENT,
      ONCCertificationG10TestKit::G10Options::US_CORE_4_REQUIREMENT,
      ONCCertificationG10TestKit::G10Options::US_CORE_5_REQUIREMENT,
      ONCCertificationG10TestKit::G10Options::US_CORE_6_REQUIREMENT,
      ONCCertificationG10TestKit::G10Options::US_CORE_7_REQUIREMENT

    ].each do |us_core_version_requirement|
      ONCCertificationG10TestKit::G10CertificationSuite.setup_validator(us_core_version_requirement)
    end
  end

  describe 'with HL7 validator wrapper' do
    before do
      reset_g10_validators
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
