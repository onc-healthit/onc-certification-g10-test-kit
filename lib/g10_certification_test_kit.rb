# TODO: Remove when this functionality is released in core
module Inferno
  module DSL
    module Configurable
      def config(new_configuration = {})
        @config ||= Configuration.new

        return @config if new_configuration.blank?

        @config.apply(new_configuration)

        children.each { |child| child.config(new_configuration) }

        @config
      end
    end
  end
end
require 'smart_app_launch_test_kit'
require 'us_core'

require_relative 'g10_certification_test_kit/smart_app_launch_invalid_aud_group'
require_relative 'g10_certification_test_kit/smart_invalid_token_group'
require_relative 'g10_certification_test_kit/smart_limited_app_group'
require_relative 'g10_certification_test_kit/smart_standalone_patient_app_group'
require_relative 'g10_certification_test_kit/smart_ehr_practitioner_app_group'
require_relative 'g10_certification_test_kit/smart_public_standalone_launch_group'
require_relative 'g10_certification_test_kit/terminology_binding_validator'
require_relative 'g10_certification_test_kit/visual_inspection_and_attestations_group'
require_relative 'inferno/terminology'

Inferno::Terminology::Loader.load_validators

module G10CertificationTestKit
  class G10CertificationSuite < Inferno::TestSuite
    title '2015 Edition Cures Update - Standardized API Testing (v2 Preview)'
    id :g10_certification

    WARNING_INCLUSION_FILTERS = [
      /Unknown CodeSystem/,
      /Unknown ValueSet/
    ].freeze

    validator do
      url ENV.fetch('VALIDATOR_URL', 'http://validator_service:4567')
      exclude_message do |message|
        if message.type == 'info' ||
           (message.type == 'warning' && WARNING_INCLUSION_FILTERS.none? { |filter| filter.match? message.message }) ||
           USCore::USCoreTestSuite::VALIDATION_MESSAGE_FILTERS.any? { |filter| filter.match? message.message }
          true
        else
          false
        end
      end
      perform_additional_validation do |resource, profile_url|
        metadata = USCore::USCoreTestSuite.metadata.find do |metadata_candidate|
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
            description: 'URL of the FHIR endpoint used by SMART applications',
            default: 'https://inferno.healthit.gov/reference-server/r4'
      input :bearer_token, optional: true, locked: true

      fhir_client do
        url :url
        bearer_token :bearer_token
      end

      test do
        id :preparation
        title 'Test preparation'
        input :standalone_access_token, optional: true, locked: true
        input :ehr_access_token, optional: true, locked: true
        # input :standalone_refresh_token, optional: true, locked: true
        # input :ehr_refresh_token, optional: true, locked: true

        output :bearer_token

        run do
          output bearer_token: standalone_access_token.presence || ehr_access_token.presence
        end
      end

      USCore::USCoreTestSuite.groups.each do |group|
        id = group.ancestors[1].id
        group from: id, exclude_optional: true
      end
    end

    group do
      title 'TODO: Multi-Patient API'
      description %(
        Demonstrate the ability to export clinical data for multiple patients in
        a group using [FHIR Bulk Data Access
        IG](https://hl7.org/fhir/uv/bulkdata/). This test uses [Backend Services
        Authorization](https://hl7.org/fhir/uv/bulkdata/authorization/index.html)
        to obtain an access token from the server. After authorization, a group
        level bulk data export request is initialized. Finally, this test reads
        exported NDJSON files from the server and validates the resources in
        each file. To run the test successfully, the selected group export is
        required to have every type of resource mapped to [USCDI data
        elements](https://www.healthit.gov/isa/us-core-data-interoperability-uscdi).
        Additionally, it is expected the server will provide Encounter,
        Location, Organization, and Practitioner resources as they are
        referenced as must support elements in required resources.
      )

      test do
        title 'TODO'

        run { pass }
      end
    end

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
      group from: :g10_smart_invalid_aud
      group from: :g10_smart_invalid_token_request

      group from: :g10_visual_inspection_and_attestations
    end
  end
end
