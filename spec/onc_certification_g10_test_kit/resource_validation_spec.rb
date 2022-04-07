RSpec.describe 'Resource Validation' do # rubocop:disable RSpec/DescribeClass
  let(:runnable) { ONCCertificationG10TestKit::G10CertificationSuite.groups.first.groups.first.tests.first.new }
  let(:resource) { FHIR.from_contents('{"resourceType": "Immunization", "id": "123"}') }
  let(:validator_url) { runnable.find_validator(:default).url }
  let(:operation_outcome_string) do
    File.read(File.join(__dir__, '..', 'fixtures', 'OperationOutcome-code-invalid-1.json'))
  end

  it 'excludes invalid-code messages' do
    stub_request(:post, "#{validator_url}/validate?profile=PROFILE")
      .to_return(status: 200, body: operation_outcome_string)

    expect(runnable.resource_is_valid?(resource: resource, profile_url: 'PROFILE')).to be(true)
    expect(runnable.messages.length).to be_zero
  end
end
