require 'smart_app_launch_test_kit'
require 'us_core_test_kit'

require_relative 'onc_certification_g10_test_kit/configuration_checker'
require_relative 'onc_certification_g10_test_kit/version'

require_relative 'onc_certification_g10_test_kit/smart_app_launch_invalid_aud_group'
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
        if message.type == 'info' ||
           (message.type == 'warning' && WARNING_INCLUSION_FILTERS.none? { |filter| filter.match? message.message }) ||
           USCoreTestKit::USCoreTestSuite::VALIDATION_MESSAGE_FILTERS.any? { |filter| filter.match? message.message }
          true
        else
          false
        end
      end
      perform_additional_validation do |resource, profile_url|
        metadata = USCoreTestKit::USCoreTestSuite.metadata.find do |metadata_candidate|
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
      @jwks_json ||= File.read(File.join(__dir__, 'onc_certification_g10_test_kit', 'bulk_data_jwks.json'))
    end

    def self.well_known_route_handler
      ->(_env) { [200, {}, [jwks_json]] }
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

      This test kit is the successor to "Inferno Program Edition", and is
      currently in preview status.  Please [create an
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
        Url, if the server supports it:

        * `#{Inferno::Application[:base_url]}/custom/g10_certification/.well-known/jwks.json`
      )

    group from: 'g10_smart_standalone_patient_app'

    group from: 'g10_smart_limited_app'

    group from: 'g10_smart_ehr_practitioner_app'

    group do
      id :single_patient_api
      title 'Single Patient API'
      description %(
        For each of the relevant USCDI data elements provided in the
        CapabilityStatement, this test executes the [required supported
        searches](http://www.hl7.org/fhir/us/core/STU3.1.1/CapabilityStatement-us-core-server.html)
        as defined by the US Core Implementation Guide v3.1.1. The test begins
        by searching by one or more patients, with the expectation that the
        Bearer token provided to the test grants access to all USCDI resources.
        It uses results returned from that query to generate other queries and
        checks that the results are consistent with the provided search
        parameters. It then performs a read on each Resource returned and
        validates the response against the relevant
        [profile](http://www.hl7.org/fhir/us/core/STU3.1.1/profiles.html) as
        currently defined in the US Core Implementation Guide. All MUST SUPPORT
        elements must be seen before the test can pass, as well as Data Absent
        Reason to demonstrate that the server can properly handle missing data.
        Note that Encounter, Organization and Practitioner resources must be
        accessible as references in some US Core profiles to satisfy must
        support requirements, and those references will be validated to their US
        Core profile. These resources will not be tested for FHIR search
        support.
      )
      run_as_group

      input :url,
            title: 'FHIR Endpoint',
            description: 'URL of the FHIR endpoint used by SMART applications'
      input :smart_credentials,
            title: 'SMART App Launch Credentials',
            type: :oauth_credentials,
            locked: true

      fhir_client do
        url :url
        oauth_credentials :smart_credentials
      end

      USCoreTestKit::USCoreTestSuite.groups.each do |group|
        test_group = group.ancestors[1]
        id = test_group.id

        group_config = {}
        if test_group.respond_to?(:metadata) && test_group.metadata.delayed?
          test_group.children.reject! { |child| child.include? USCoreTestKit::SearchTest }
          group_config[:options] = { read_all_resources: true }
        end

        group(from: id, exclude_optional: true, config: group_config)
      end
    end

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
      group from: :g10_smart_invalid_token_request

      group from: :g10_visual_inspection_and_attestations
    end
  end
end

# TODO: address this input issue in core
Inferno::Repositories::Tests.new
  .find('g10_certification-g10_smart_limited_app-smart_standalone_launch-standalone_auth_tls')
  .config(
    inputs: {
      url: {
        title: 'Standalone Authorization URL',
        description: '',
        default: ''
      }
    }
  )

Inferno::Repositories::Tests.new
  .find('g10_certification-g10_smart_limited_app-smart_standalone_launch-standalone_token_tls')
  .config(
    inputs: {
      url: {
        title: 'Standalone Token URL',
        description: '',
        default: ''
      }
    }
  )
