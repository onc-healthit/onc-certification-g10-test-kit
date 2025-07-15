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

    it 'excludes https://tx.fhir.org/r4 message' do
      operation_outcome = {
        outcomes: [
          {
            issues: [
              {
                location: 'DocumentReference.content[0].attachment.contentType',
                message: 'The System URI could not be determined for the code \'text/plain\' in the ' \
                         'ValueSet \'http://hl7.org/fhir/ValueSet/mimetypes|4.0.1\': include #0 has ' \
                         'system urn:ietf:bcp:13 which could not be found, and the server returned error ' \
                         '[Error from https://tx.fhir.org/r4: The code System "urn:ietf:bcp:13" has a ' \
                         'grammar, and cannot be enumerated directly]',
                type: 'CODEINVALID',
                level: 'ERROR'
              }
            ]
          }
        ],
        sessionId: '7c0cb248-4dd9-4063-9ed9-03623bbe221a'
      }

      stub_request(:post, "#{validator_url}/validate")
        .to_return(status: 200, body: operation_outcome.to_json)

      expect(runnable.resource_is_valid?(resource:, profile_url: 'PROFILE')).to be(true)
      expect(runnable.messages.length).to be_zero
    end
  end
end
