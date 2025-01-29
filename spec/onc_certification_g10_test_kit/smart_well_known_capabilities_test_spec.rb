RSpec.describe ONCCertificationG10TestKit::SMARTWellKnownCapabilitiesTest do
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
  let(:well_known_config) do
    {
      capabilities: required_capabilities
    }
  end
  let(:required_capabilities) do
    [
      'launch-ehr',
      'client-confidential-symmetric',
      'sso-openid-connect',
      'context-banner',
      'context-style',
      'context-ehr-patient',
      'permission-offline',
      'permission-user'
    ]
  end
  let(:test_config) do
    Inferno::DSL::Configurable::Configuration.new(options: { required_capabilities: })
  end

  context 'when `launch-ehr` capability is present' do
    context 'when using US Core 3' do
      before do
        allow_any_instance_of(test).to(
          receive(:suite_options).and_return(ONCCertificationG10TestKit::G10Options::US_CORE_3_REQUIREMENT)
        )
        allow_any_instance_of(test).to(receive(:config).and_return(test_config))
      end

      it 'does not require `context-ehr-encounter`' do
        inputs = { well_known_configuration: JSON.generate(well_known_config) }

        result = run(test, inputs)

        expect(result.result).to eq('pass')
      end
    end

    context 'when using US Core 5' do
      before do
        allow_any_instance_of(test).to(
          receive(:suite_options).and_return(ONCCertificationG10TestKit::G10Options::US_CORE_5_REQUIREMENT)
        )
        allow_any_instance_of(test).to(receive(:config).and_return(test_config))
      end

      it 'fails if `context-ehr-encounter` is not present' do
        inputs = { well_known_configuration: JSON.generate(well_known_config) }

        result = run(test, inputs)

        expect(result.result).to eq('fail')
        expect(result.result_message).to include('context-ehr-encounter')
      end

      it 'passes if `context-ehr-encounter` is present' do
        well_known_config[:capabilities] += ['context-ehr-encounter']
        inputs = { well_known_configuration: JSON.generate(well_known_config) }

        result = run(test, inputs)

        expect(result.result).to eq('pass')
      end

      it 'does not modify the config' do
        original_capabilities = JSON.generate(test_config.options[:required_capabilities])
        inputs = { well_known_configuration: JSON.generate(well_known_config) }

        run(test, inputs)

        expect(JSON.generate(test_config.options[:required_capabilities])).to eq(original_capabilities)
      end
    end
  end
end
