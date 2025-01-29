RSpec.describe ONCCertificationG10TestKit::PatientContextTest do
  def run(runnable, inputs = {})
    test_run_params = { test_session_id: test_session.id }.merge(runnable.reference_hash)
    test_run = Inferno::Repositories::TestRuns.new.create(test_run_params)
    inputs.each do |name, value|
      session_data_repo.save(
        test_session_id: test_session.id,
        name:,
        value:,
        type: runnable.config.input_type(name)
      )
    end
    Inferno::TestRunner.new(test_session:, test_run:).run(runnable)
  end

  let(:test) { described_class }
  let(:suite_id) { 'g10_certification' }
  let(:test_session) { repo_create(:test_session, test_suite_id: suite_id) }
  let(:session_data_repo) { Inferno::Repositories::SessionData.new }
  let(:smart_credentials) do
    {
      access_token: 'ACCESS_TOKEN',
      refresh_token: 'REFRESH_TOKEN',
      expires_in: 3600,
      client_id: 'CLIENT_ID',
      token_retrieval_time: Time.now.iso8601,
      token_url: 'http://example.com/token'
    }.to_json
  end
  let(:default_inputs) do
    {
      url: 'http://example.com/fhir',
      patient_id: '123',
      smart_credentials:
    }
  end

  it 'skips if the access token is blank' do
    credentials = Inferno::DSL::OAuthCredentials.new(JSON.parse(smart_credentials).merge('access_token' => ''))
    inputs = default_inputs.merge(smart_credentials: credentials.to_s)
    result = run(test, inputs)

    expect(result.result).to eq('skip')
    expect(result.result_message).to match(/No access token/)
  end

  it 'skips if the patient id is blank' do
    inputs = default_inputs.merge(patient_id: '')
    result = run(test, inputs)

    expect(result.result).to eq('skip')
    expect(result.result_message).to match(/patient/)
  end

  it 'passes if the patient can be retrieved' do
    patient_request =
      stub_request(:get, "#{default_inputs[:url]}/Patient/#{default_inputs[:patient_id]}")
        .to_return(status: 200, body: FHIR::Patient.new(id: default_inputs[:patient_id]).to_json)
    result = run(test, default_inputs)

    expect(result.result).to eq('pass')
    expect(patient_request).to have_been_made
  end

  it 'fails if a non-200 response is received' do
    patient_request =
      stub_request(:get, "#{default_inputs[:url]}/Patient/#{default_inputs[:patient_id]}")
        .to_return(status: 404, body: FHIR::Patient.new(id: default_inputs[:patient_id]).to_json)
    result = run(test, default_inputs)

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/200/)
    expect(patient_request).to have_been_made
  end

  it 'fails if a Patient resource is not received' do
    patient_request =
      stub_request(:get, "#{default_inputs[:url]}/Patient/#{default_inputs[:patient_id]}")
        .to_return(status: 200, body: FHIR::Practitioner.new(id: default_inputs[:patient_id]).to_json)
    result = run(test, default_inputs)

    expect(result.result).to eq('fail')
    expect(result.result_message).to match(/Practitioner/)
    expect(patient_request).to have_been_made
  end

  context 'when refresh_test is true' do
    before do
      allow_any_instance_of(described_class).to(
        receive(:config).and_return(OpenStruct.new(options: { refresh_test: true }))
      )
    end

    it 'skips if the refresh request was not successful' do
      allow_any_instance_of(described_class).to(
        receive(:request).and_return(Inferno::Entities::Request.new(status: 500))
      )

      result = run(test, default_inputs)

      expect(result.result).to eq('skip')
      expect(result.result_message).to match(/refresh/)
    end

    it 'passes if the refresh request was successful and the Patient resource can be retrieved' do
      allow_any_instance_of(described_class).to(
        receive(:requests).and_return(
          [Inferno::Entities::Request.new(
            status: 200,
            verb: 'post',
            url: 'http://example.com',
            direction: 'outgoing',
            test_session_id: test_session.id,
            result_id: repo_create(:result).id
          )]
        )
      )
      patient_request =
        stub_request(:get, "#{default_inputs[:url]}/Patient/#{default_inputs[:patient_id]}")
          .to_return(status: 200, body: FHIR::Patient.new(id: default_inputs[:patient_id]).to_json)

      result = run(test, default_inputs)

      expect(result.result).to eq('pass')
      expect(patient_request).to have_been_made
    end
  end
end
