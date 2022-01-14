module ValidationUtils
  include USCore::MustSupportTest

  MAX_NUM_COLLECTED_LINES = 100
  MIN_RESOURCE_COUNT = 2

  def patient_ids_seen
    scratch[:patient_ids_seen] = [] if scratch[:patient_ids_seen].nil?
    scratch[:patient_ids_seen]
  end

  def metadata
    scratch[:metadata]
  end

  # TODO: Delete this once core functionality is merged in
  def stream(block, url = '', name: nil, **options)
    store_request('outgoing', name) do
      Faraday.get(url, nil, options[:headers]) { |req| req.options.on_data = block }
    end
  end

  def get_file(endpoint, use_token = true)
    headers = { accept: 'application/fhir+ndjson' }
    headers.merge!({ authorization: "Bearer #{bearer_token}" }) if use_token

    get(endpoint, headers: headers)
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

  # Unsure what to do with this
  def determine_profile(resource)
    return nil if resource_type == 'Device' && !predefined_device_type?(resource)
  end

  # Unsure what to do with this
  def predefined_device_type?(resource)
    return true unless bulk_device_types_in_group.present?

    expected = Set.new(bulk_device_types_in_group.split(',').map(&:strip))

    actual = resource&.type&.coding&.filter_map do |coding|
      coding.code if coding.system.nil? || coding.system == 'http://snomed.info/sct'
    end

    (expected & actual).any?
  end

  def check_file_request(file, validate_all, lines_to_validate, resource_type, metadata_arr)
    headers = { accept: 'application/fhir+ndjson' }
    headers.merge!({ authorization: "Bearer #{bearer_token}" }) if requires_access_token

    line_count = 0
    line_collection = []
    resources = Hash.new { |h, k| h[k] = [] }

    process_line = proc { |line|
      unless validate_all || line_count < lines_to_validate || (resource_type == 'Patient' && patient_ids_seen.length < MIN_RESOURCE_COUNT)
        next
      end
      next if line.nil? || line.strip.empty? || line.strip.delete('{}').empty?

      line_collection << line if line_count < MAX_NUM_COLLECTED_LINES
      line_count += 1

      begin
        resource = FHIR.from_contents(line)
        # TODO: Guess profile here and still store by url -- don't rely on meta at all
        resource.meta.profile.each { |profile_url| resources[profile_url] << resource }
      rescue StandardError
        skip "Server response at line \"#{line_count}\" is not a processable FHIR resource."
      end

      type = resource.class.name.demodulize
      skip_if type != resource_type,
              "Resource type \"#{type}\" at line \"#{line_count}\" does not match type defined in output \"#{resource_type}\")"

      patient_ids_seen << resource.id if resource_type == 'Patient'

      assert metadata_arr.any? { |profile|
               resource_is_valid?(resource: resource, profile_url: profile.profile_url)
             }, "Resource does not conform to the #{resource_type} profile"
    }

    process_headers = proc { |response|
      header = response[:headers].find { |header| header.name.downcase == 'content-type' }
      value = header.value || 'type left unspecified.'
      assert value.start_with?('application/fhir+ndjson'),
             "Content type must have 'application/fhir+ndjson' but found '#{value}'"
    }

    stream_ndjson(file['url'], headers, process_line, process_headers)

    metadata_arr.each do |profile|
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

    line_count
  end

  def perform_bulk_export_validation_test(resource_type, metadata)
    skip 'Could not verify this functionality when Bulk Status Output is not provided' unless status_output.present?
    unless requires_access_token.present?
      skip 'Could not verify this functionality when requiresAccessToken is not provided'
    end
    if requires_access_token && !bearer_token.present?
      skip 'Could not verify this functionality when Bearer Token is required and not provided'
    end

    file_list = JSON.parse(status_output).select { |file| file['type'] == resource_type }

    skip "No #{resource_type} resource file item returned by server." if file_list.empty?

    success_count = 0

    file_list.each do |file|
      success_count += check_file_request(file, lines_to_validate.blank?, lines_to_validate.to_i, resource_type,
                                          metadata)
    end

    pass "Successfully validated #{success_count} #{resource_type} resource(s)."
  end
end
