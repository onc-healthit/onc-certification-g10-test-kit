require 'smart_app_launch_test_kit'
require 'us_core_test_kit/generated/v3.1.1/us_core_test_suite'

require_relative 'onc_certification_g10_test_kit/configuration_checker'
require_relative 'onc_certification_g10_test_kit/version'

require_relative 'onc_certification_g10_test_kit/single_patient_api_group'
require_relative 'onc_certification_g10_test_kit/smart_app_launch_invalid_aud_group'
require_relative 'onc_certification_g10_test_kit/smart_invalid_launch_group'
require_relative 'onc_certification_g10_test_kit/smart_invalid_token_group'
require_relative 'onc_certification_g10_test_kit/smart_limited_app_group'
require_relative 'onc_certification_g10_test_kit/smart_standalone_patient_app_group'
require_relative 'onc_certification_g10_test_kit/smart_ehr_practitioner_app_group'
require_relative 'onc_certification_g10_test_kit/smart_public_standalone_launch_group'
require_relative 'onc_certification_g10_test_kit/multi_patient_api'
require_relative 'onc_certification_g10_test_kit/terminology_binding_validator'
require_relative 'onc_certification_g10_test_kit/token_revocation_group'
require_relative 'onc_certification_g10_test_kit/visual_inspection_and_attestations_group'
require_relative 'inferno/terminology'

Inferno::Terminology::Loader.load_validators

module ONCCertificationG10TestKit
  class G10CertificationSuite < Inferno::TestSuite
    title 'ONC Certification (g)(10) Standardized API'
    short_title '(g)(10) Standardized API'
    version VERSION
    id :g10_certification

    check_configuration do
      ConfigurationChecker.new.configuration_messages
    end

    WARNING_INCLUSION_FILTERS = [
      /Unknown CodeSystem/,
      /Unknown ValueSet/
    ].freeze

    validator do
      url ENV.fetch('G10_VALIDATOR_URL', 'http://validator_service:4567')

      exclude_message do |message|
        us_core_message_filters = USCoreTestKit::USCoreV311::USCoreTestSuite::VALIDATION_MESSAGE_FILTERS
        if message.type == 'info' ||
           (message.type == 'warning' && WARNING_INCLUSION_FILTERS.none? { |filter| filter.match? message.message }) ||
           us_core_message_filters.any? { |filter| filter.match? message.message } ||
           (
             message.type == 'error' && (
               message.message.match?(/\A\S+: Unknown Code/) ||
               message.message.match?(/\A\S+: None of the codings provided are in the value set/)
             )
           )
          true
        else
          false
        end
      end

      perform_additional_validation do |resource, profile_url|
        metadata = USCoreTestKit::USCoreV311::USCoreTestSuite.metadata.find do |metadata_candidate|
          metadata_candidate.profile_url == profile_url
        end

        next if metadata.nil?

        metadata.bindings
          .select { |binding_definition| binding_definition[:strength] == 'required' }
          .flat_map do |binding_definition|
            TerminologyBindingValidator.validate(resource, binding_definition)
          rescue Inferno::UnknownValueSetException, Inferno::UnknownCodeSystemException => e
            { type: 'warning', message: e.message }
          end.compact
      end
    end

    def self.jwks_json
      bulk_data_jwks = JSON.parse(File.read(File.join(__dir__, 'onc_certification_g10_test_kit', 'bulk_data_jwks.json')))
      @jwks_json ||= JSON.pretty_generate({
        keys: bulk_data_jwks['keys'].select { |key| key['key_ops']&.include?('verify') }
      })
    end

    def self.well_known_route_handler
      ->(_env) { [200, { 'Content-Type' => 'application/json' }, [jwks_json]] }
    end

    route(
      :get,
      '/.well-known/jwks.json',
      well_known_route_handler
    )

    description %(
      The ONC Certification (g)(10) Standardized API Test Kit is a testing tool for
      Health Level 7 (HL7®) Fast Healthcare Interoperability Resources (FHIR®)
      services seeking to meet the requirements of the Standardized API for
      Patient and Population Services criterion § 170.315(g)(10) in the 2015
      Edition Cures Update.

      This test kit is the successor to "Inferno Program Edition". Please [create an
      issue](https://github.com/inferno-framework/g10-certification-test-kit/issues)
      if there are discrepencies between these tests and the "Inferno Program
      Edition v1.9" tests.

      To get started, please first register the Inferno client as a SMART App
      with the following information:

      * SMART Launch URI: `#{SMARTAppLaunch::AppLaunchTest.config.options[:launch_uri]}`
      * OAuth Redirect URI: `#{SMARTAppLaunch::AppRedirectTest.config.options[:redirect_uri]}`

      For the multi-patient API, register Inferno with the following JWK Set
      Url:

      * `#{Inferno::Application[:base_url]}/custom/g10_certification/.well-known/jwks.json`

      Systems must pass all tests in order to qualify for ONC certification.
    )

    input_instructions %(
        Register Inferno as a SMART app using the following information:

        * Launch URI: `#{SMARTAppLaunch::AppLaunchTest.config.options[:launch_uri]}`
        * Redirect URI: `#{SMARTAppLaunch::AppRedirectTest.config.options[:redirect_uri]}`

        For the multi-patient API, register Inferno with the following JWK Set
        Url:

        * `#{Inferno::Application[:base_url]}/custom/g10_certification/.well-known/jwks.json`
      )

    group from: 'g10_smart_standalone_patient_app'

    group from: 'g10_smart_limited_app'

    group from: 'g10_smart_ehr_practitioner_app'

    group from: 'g10_single_patient_api'

    group from: 'multi_patient_api'

    group do
      title 'Additional Tests'
      description %(
        Not all requirements that need to be tested fit within the previous
        scenarios. The tests contained in this section addresses remaining
        testing requirements. Each of these tests need to be run independently.
        Please read the instructions for each in the 'About' section, as they
        may require special setup on the part of the tester.
      )

      group from: :g10_public_standalone_launch
      group from: :g10_token_revocation

      group from: :g10_smart_invalid_aud
      group from: :g10_smart_invalid_launch_param
      group from: :g10_smart_invalid_token_request

      group from: :g10_visual_inspection_and_attestations
    end
  end
end
