RSpec.describe 'Resource Validation' do # rubocop:disable RSpec/DescribeClass
  let(:runnable) { ONCCertificationG10TestKit::G10CertificationSuite.groups.first.groups.first.tests.first.new }
  let(:resource) { FHIR.from_contents('{"resourceType": "Immunization", "id": "123"}') }
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
