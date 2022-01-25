require_relative 'profile_guesser'

module BulkExportValidationTester
  include USCore::MustSupportTest
  include ProfileGuesser

  MAX_NUM_COLLECTED_LINES = 100
  MIN_RESOURCE_COUNT = 2

  def observation_profiles
    [USCore::PediatricBmiForAgeGroup.metadata, USCore::PediatricWeightForHeightGroup.metadata,
     USCore::ObservationLabGroup.metadata, USCore::PulseOximetryGroup.metadata, USCore::SmokingstatusGroup.metadata,
     USCore::HeadCircumferenceGroup.metadata, USCore::BpGroup.metadata, USCore::BodyheightGroup.metadata,
     USCore::BodytempGroup.metadata, USCore::BodyweightGroup.metadata, USCore::HeartrateGroup.metadata,
     USCore::ResprateGroup.metadata]
  end

  def diagnostic_profiles
    [USCore::DiagnosticReportLabGroup.metadata, USCore::DiagnosticReportNoteGroup.metadata]
  end

  def determine_profiles
    return observation_profiles if resource_type == 'Observation'
    return diagnostic_profiles if resource_type == 'DiagnosticReport'

    ["USCore::#{resource_type}Group".constantize.metadata]
  end

  def profiles
    @profiles ||= determine_profiles
  end

  def metadata
    scratch[:metadata] ||= []
  end

  def patient_ids_seen
    scratch[:patient_ids_seen] ||= []
  end

  # TODO: Delete this once core functionality is merged in
  def stream(block, url = '', name: nil, **options)
    store_request('outgoing', name) do
      Faraday.get(url, nil, options[:headers]) { |req| req.options.on_data = block }
    end
  end

  def build_headers(use_token)
    headers = { accept: 'application/fhir+ndjson' }
    headers.merge!({ authorization: "Bearer #{bearer_token}" }) if use_token
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

  def predefined_device_type?(resource)
    return true if bulk_device_types_in_group.blank?

    expected = Set.new(bulk_device_types_in_group.split(',').map(&:strip))

    actual = resource&.type&.coding&.filter_map do |coding|
      coding.code if coding.system.nil? || coding.system == 'http://snomed.info/sct'
    end

    (expected & actual).any?
  end

  def determine_profile(resource)
    return [] if resource.resourceType == 'Device' && !predefined_device_type?(resource)

    guess_profile(resource)
  end

  def validate_conformance(resources)
    profiles.each do |profile|
      skip_if resources[profile.profile_url].blank?,
              "No #{resource_type} resources found that conform to profile: #{profile.profile_url}."
      scratch[:metadata] = profile
      @missing_elements = nil
      @missing_slices = nil
      begin
        perform_must_support_test(resources[profile.profile_url])
      rescue Inferno::Exceptions::PassException => e
        next
      end
    end
  end

  def check_file_request(url, validate_all, lines_to_validate)
    line_count = 0
    resources = Hash.new { |h, k| h[k] = [] }

    process_line = proc { |line|
      next unless validate_all ||
                  line_count < lines_to_validate ||
                  (resource_type == 'Patient' && patient_ids_seen.length < MIN_RESOURCE_COUNT)

      line_count += 1

      begin
        resource = FHIR.from_contents(line)
      rescue StandardError
        skip "Server response at line \"#{line_count}\" is not a processable FHIR resource."
      end

      skip_if resource.resourceType != resource_type,
              "Resource type \"#{resource.resourceType}\" at line \"#{line_count}\" does not match type defined in output \"#{resource_type}\")"

      determine_profile(resource).each { |profile| resources[profile] << resource }
      patient_ids_seen << resource.id if resource_type == 'Patient'

      assert profiles.any? { |profile|
               resource_is_valid?(resource: resource, profile_url: profile.profile_url)
             }, "Resource does not conform to the #{resource_type} profile"
    }

    process_headers = proc { |response|
      value = (response[:headers].find { |header| header.name.downcase == 'content-type' })&.value
      assert value.start_with?('application/fhir+ndjson'),
             "Content type must have 'application/fhir+ndjson' but found '#{value}'"
    }

    stream_ndjson(url, build_headers(requires_access_token), process_line, process_headers)
    validate_conformance(resources)

    line_count
  end

  def perform_bulk_export_validation
    skip_if !status_output, 'Could not verify this functionality when Bulk Status Output is not provided'
    skip_if !requires_access_token, 'Could not verify this functionality when requiresAccessToken is not provided'
    skip_if (requires_access_token && !bearer_token),
            'Could not verify this functionality when Bearer Token is required and not provided'

    file_list = JSON.parse(status_output).select { |file| file['type'] == resource_type }
    skip_if file_list.empty?, "No #{resource_type} resource file item returned by server."

    success_count = 0
    file_list.each do |file|
      success_count += check_file_request(file['url'], lines_to_validate.blank?, lines_to_validate.to_i)
    end

    pass "Successfully validated #{success_count} #{resource_type} resource(s)."
  end
end
