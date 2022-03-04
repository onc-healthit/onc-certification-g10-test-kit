require_relative 'profile_guesser'

module ONCCertificationG10TestKit
  module BulkExportValidationTester
    include USCoreTestKit::MustSupportTest
    include ProfileGuesser

    attr_reader :metadata

    MAX_NUM_COLLECTED_LINES = 100
    MIN_RESOURCE_COUNT = 2
    OMIT_KLASS = ['Medication', 'Location'].freeze

    def observation_metadata
      [
        USCoreTestKit::PediatricBmiForAgeGroup.metadata,
        USCoreTestKit::PediatricWeightForHeightGroup.metadata,
        USCoreTestKit::ObservationLabGroup.metadata,
        USCoreTestKit::PulseOximetryGroup.metadata,
        USCoreTestKit::SmokingstatusGroup.metadata,
        USCoreTestKit::HeadCircumferenceGroup.metadata,
        USCoreTestKit::BpGroup.metadata,
        USCoreTestKit::BodyheightGroup.metadata,
        USCoreTestKit::BodytempGroup.metadata,
        USCoreTestKit::BodyweightGroup.metadata,
        USCoreTestKit::HeartrateGroup.metadata,
        USCoreTestKit::ResprateGroup.metadata
      ]
    end

    def diagnostic_metadata
      [USCoreTestKit::DiagnosticReportLabGroup.metadata, USCoreTestKit::DiagnosticReportNoteGroup.metadata]
    end

    def determine_metadata
      return observation_metadata if resource_type == 'Observation'
      return diagnostic_metadata if resource_type == 'DiagnosticReport'

      if resource_type == 'Location' || resource_type == 'Medication'
        return Array.wrap(USCoreTestKit::USCoreTestSuite.metadata.find do |meta|
                            meta.resource == resource_type
                          end)
      end
      ["USCoreTestKit::#{resource_type}Group".constantize.metadata]
    end

    def metadata_list
      @metadata_list ||= determine_metadata
    end

    def patient_ids_seen
      scratch[:patient_ids_seen] ||= []
    end

    def build_headers(use_token)
      headers = { accept: 'application/fhir+ndjson' }
      headers.merge!({ authorization: "Bearer #{bearer_token}" }) if use_token == 'true'
      headers
    end

    def stream_ndjson(endpoint, headers, process_chunk_line, process_response)
      hanging_chunk = String.new

      process_body = proc { |chunk|
        hanging_chunk << chunk
        chunk_by_lines = hanging_chunk.lines

        hanging_chunk = chunk_by_lines.pop || String.new

        chunk_by_lines.each do |elem|
          process_chunk_line.call(elem)
        end
      }

      stream(process_body, endpoint, headers: headers)

      process_chunk_line.call(hanging_chunk)
      process_response.call(response)
    end

    def predefined_device_type?(resource) # rubocop:disable Metrics/CyclomaticComplexity
      return true if bulk_device_types_in_group.blank?

      expected = Set.new(bulk_device_types_in_group.split(',').map(&:strip))

      actual = resource&.type&.coding&.filter_map do |coding|
        coding.code if coding.system.nil? || coding.system == 'http://snomed.info/sct'
      end

      (expected & actual).any?
    end

    def determine_profile(resource)
      return if resource.resourceType == 'Device' && !predefined_device_type?(resource)

      guess_profile(resource)
    end

    def validate_conformance(resources)
      metadata_list.each do |meta|
        skip_if resources[meta.profile_url].blank?,
                "No #{resource_type} resources found that conform to profile: #{meta.profile_url}."
        @metadata = meta
        @missing_elements = nil
        @missing_slices = nil
        begin
          perform_must_support_test(resources[meta.profile_url])
        rescue Inferno::Exceptions::PassException
          next
        end
      end
    end

    def check_file_request(url) # rubocop:disable Metrics/CyclomaticComplexity
      line_count = 0
      resources = Hash.new { |h, k| h[k] = [] }

      process_line = proc { |line|
        next unless lines_to_validate.blank? ||
                    line_count < lines_to_validate.to_i ||
                    (resource_type == 'Patient' && patient_ids_seen.length < MIN_RESOURCE_COUNT)

        line_count += 1

        begin
          resource = FHIR.from_contents(line)
        rescue StandardError
          skip "Server response at line \"#{line_count}\" is not a processable FHIR resource."
        end

        if resource.resourceType != resource_type
          message = "Resource type \"#{resource.resourceType}\" at line \"#{line_count}\" does not match type" \
                    " defined in output \"#{resource_type}\""
          omit_if (OMIT_KLASS.include? resource_type), message
          assert false, message
        end

        profile_url = determine_profile(resource)
        resources[profile_url] << resource
        scratch[:patient_ids_seen] = patient_ids_seen | [resource.id] if resource_type == 'Patient'

        skip_if !resource_is_valid?(resource: resource, profile_url: profile_url),
                "Resource at line \"#{line_count}\" does not conform to profile \"#{profile_url}\"."
      }

      process_headers = proc { |response|
        value = (response[:headers].find { |header| header.name.downcase == 'content-type' })&.value
        unless value&.start_with?('application/fhir+ndjson')
          skip "Content type must have 'application/fhir+ndjson' but found '#{value}'"
        end
      }

      stream_ndjson(url, build_headers(requires_access_token), process_line, process_headers)
      validate_conformance(resources)

      line_count
    end

    def omit_or_skip(message)
      omit_if (OMIT_KLASS.include? resource_type), message
      skip message
    end

    def perform_bulk_export_validation
      skip_if status_output.blank?, 'Could not verify this functionality when Bulk Status Output is not provided'
      skip_if (requires_access_token == 'true' && bearer_token.blank?),
              'Could not verify this functionality when Bearer Token is required and not provided'

      file_list = JSON.parse(status_output).select { |file| file['type'] == resource_type }
      message = "No #{resource_type} resource file item returned by server."
      omit_or_skip(message) if file_list.empty?

      success_count = 0
      file_list.each do |file|
        success_count += check_file_request(file['url'])
      end

      pass "Successfully validated #{success_count} #{resource_type} resource(s)."
    end
  end
end
