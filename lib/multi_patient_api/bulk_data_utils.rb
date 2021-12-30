require 'pry' #TODO: REMOVE
require 'json/jwt' #TODO: REMOVE

module AuthorizationUtils

	def bulk_data_jwks
		@bulk_data_jwks ||= JSON.parse(File.read(File.join(File.dirname(__FILE__), 'bulk_data_jwks.json')))
	end 

	def bulk_selected_private_key(encryption)
		bulk_private_key_set = bulk_data_jwks['keys'].select { |key| key['key_ops']&.include?('sign') }
		bulk_private_key_set.find { |key| key['alg'] == encryption }
	end

	def create_client_assertion(encryption_method:, iss:, sub:, aud:, exp:, jti:)
		bulk_private_key = bulk_selected_private_key(encryption_method)
		jwt_token = JSON::JWT.new(iss: iss, sub: sub, aud: aud, exp: exp, jti: jti).compact
		jwk = JSON::JWK.new(bulk_private_key)

		jwt_token.kid = jwk['kid']
		jwk_private_key = jwk.to_key
		client_assertion = jwt_token.sign(jwk_private_key, bulk_private_key['alg'])
	end 

	def build_authorization_request(encryption_method:,
								scope:,
								iss:,
								sub:,
								aud:,
								content_type: 'application/x-www-form-urlencoded',
								grant_type: 'client_credentials',
								client_assertion_type: 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
								exp: 5.minutes.from_now,
								jti: SecureRandom.hex(32))
		header =
			{
				content_type: content_type,
				accept: 'application/json'
			}.compact

		client_assertion = create_client_assertion(encryption_method: encryption_method, iss: iss, sub: sub, aud: aud, exp: exp, jti: jti)

		query_values =
			{
				'scope' => scope,
				'grant_type' => grant_type,
				'client_assertion_type' => client_assertion_type,
				'client_assertion' => client_assertion.to_s
			}.compact

		uri = Addressable::URI.new
		uri.query_values = query_values

		{ body: uri.query, headers: header }
	end
end 

module BulkDataUtils

	include Inferno::DSL::Assertions
	include USCore::MustSupportTest

	MAX_NUM_COLLECTED_LINES = 100
	MIN_RESOURCE_COUNT = 2

	def patient_ids_seen
		scratch[:patient_ids_seen] = [] if scratch[:patient_ids_seen].nil?
		return scratch[:patient_ids_seen]
	end 

	def resource_type 
		scratch[:resource_type]
	end 

	def metadata
		scratch[:metadata]
	end 

	def bulk_selected_private_key(encryption)
		bulk_data_jwks = JSON.parse(File.read(File.join(File.dirname(__FILE__), 'bulk_data_jwks.json')))
		bulk_private_key_set = bulk_data_jwks['keys'].select { |key| key['key_ops']&.include?('sign') }
		bulk_private_key_set.find { |key| key['alg'] == encryption }
	end

	def create_client_assertion(encryption_method:, iss:, sub:, aud:, exp:, jti:)
		bulk_private_key = bulk_selected_private_key(encryption_method)
		jwt_token = JSON::JWT.new(iss: iss, sub: sub, aud: aud, exp: exp, jti: jti).compact
		jwk = JSON::JWK.new(bulk_private_key)

		jwt_token.kid = jwk['kid']
		jwk_private_key = jwk.to_key
		client_assertion = jwt_token.sign(jwk_private_key, bulk_private_key['alg'])
	end 

	def build_authorization_request(encryption_method:,
								scope:,
								iss:,
								sub:,
								aud:,
								content_type: 'application/x-www-form-urlencoded',
								grant_type: 'client_credentials',
								client_assertion_type: 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
								exp: 5.minutes.from_now,
								jti: SecureRandom.hex(32))
		header =
			{
				content_type: content_type,
				accept: 'application/json'
			}.compact

		client_assertion = create_client_assertion(encryption_method: encryption_method, iss: iss, sub: sub, aud: aud, exp: exp, jti: jti)

		query_values =
			{
				'scope' => scope,
				'grant_type' => grant_type,
				'client_assertion_type' => client_assertion_type,
				'client_assertion' => client_assertion.to_s
			}.compact

		uri = Addressable::URI.new
		uri.query_values = query_values

		{ body: uri.query, headers: header }
	end

	def declared_export_support? 
		fhir_get_capability_statement(client: :bulk_server)

		assert_response_status([200, 201])
		assert_valid_json(request.response_body)

		definition = 'http://hl7.org/fhir/uv/bulkdata/OperationDefinition/group-export'
		capability_statement = JSON.parse(request.response_body)
		
		capability_statement['rest'].each do |rest|
			groups = rest['resource'].select { |resource| resource['type'] == 'Group' } 
			return true if groups.any? do |group|
				group.has_key?('operation') && group['operation'].any? do |operation|
					if operation['definition'].is_a? String 
						operation['definition'] == definition
					else
						operation['definition'].flatten.include?(definition)
					end
				end 
			end 
		end 
		return false
	end 
 
	def export_kick_off(use_token = true)
		headers = { accept: 'application/fhir+json', prefer: 'respond-async' } 
		headers.merge!( { authorization: "Bearer #{bearer_token}" } ) if use_token 

		id = defined?(group_id) ? group_id : 'example'
		get("Group/#{id}/$export", client: :bulk_server, name: :export, headers: headers)
	end

	def check_export_status(timeout)

		wait_time = 1
		start = Time.now

		begin
			get(client: :polling_location, headers: { authorization: "Bearer #{bearer_token}"})

			retry_after = (response[:headers].find { |header| header.name == 'retry-after' })
			retry_after_val = retry_after.nil? || retry_after.value.nil? ? 0 : retry_after.value.to_i
			wait_time = retry_after_val.positive? ? retry_after_val : wait_time *= 2

			timeout -= Time.now - start + wait_time
			sleep wait_time

		end while response[:status] == 202 and timeout > 0

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

	# TODO: Is this enough? Should it be more similar to program?
	# TODO: Write-Up what exactly your issue is 
	def determine_profile(resource)
		return nil if resource_type == 'Device' && !predefined_device_type?(resource)
	end 

	def predefined_device_type?(resource)
		return true unless bulk_device_types_in_group.present?

		expected = Set.new(bulk_device_types_in_group.split(',').map(&:strip))

		actual = resource&.type&.coding&.filter_map { |coding| coding.code if coding.system.nil? || coding.system == 'http://snomed.info/sct' }

		(expected & actual).any?
	end

	def check_file_request(file, validate_all, lines_to_validate, resource_type, metadata_arr)
		headers = { accept: 'application/fhir+ndjson' }
		headers.merge!( { authorization: "Bearer #{bearer_token}" } ) if requires_access_token
					
		line_count = 0
		line_collection = []
		resources = {}

		process_line = proc { |resource|
			next unless validate_all || line_count < lines_to_validate || (resource_type == 'Patient' && patient_ids_seen.length < MIN_RESOURCE_COUNT)
			next if resource.nil? || resource.strip.empty? || resource.strip.delete("{}").empty?

			line_collection << resource if line_count < MAX_NUM_COLLECTED_LINES
			line_count += 1
			
			begin 
				curr_resource = FHIR.from_contents(resource)
				curr_resource.meta.profile.each { |profile_url| resources[profile_url].nil? ? resources[profile_url] = Array.wrap(curr_resource) : resources[profile_url] << curr_resource }
			rescue 
				skip "Server response at line \"#{line_count}\" is not a processable FHIR resource."
			end 

			processed_resource_type = curr_resource.class.name.demodulize
			skip "Resource type \"#{processed_resource_type}\" at line \"#{line_count}\" does not match type defined in output \"#{resource_type}\")" if processed_resource_type != resource_type
			
			patient_ids_seen << curr_resource.id if resource_type == 'Patient'

			# determine_profile(resources.last)
		
			#binding.pry if resource_type == 'DocumentReference'

			binding.pry unless metadata_arr.any? { |profile| resource_is_valid?(resource: curr_resource, profile_url: profile.profile_url) } 
			 
			assert metadata_arr.any? { |profile| resource_is_valid?(resource: curr_resource, profile_url: profile.profile_url) }, "Resource does not conform to the #{resource_type} profile"
			
		}

		process_headers = proc { |response| 
			header = response[:headers].find { |header| header.name.downcase == 'content-type' }
			value = header.value || 'type left unspecified.'
			assert value.start_with?('application/fhir+ndjson'), "Content type must have 'application/fhir+ndjson' but found '#{value}'"
		}

		stream_ndjson(file['url'], headers, process_line, process_headers)

		scratch[:resource_type] = resource_type

		metadata_arr.each do |profile|
			scratch[:metadata] = profile

			@missing_elements = nil
			@missing_slices = nil
			begin 
				perform_must_support_test(resources[profile.profile_url]) 
			rescue Inferno::Exceptions::PassException => e
				next
			rescue Inferno::Exceptions::SkipException => e
				raise if metadata_arr.length == 1
				message = "No #{resource_type} resources found that conform to profile: #{profile.profile_url}."
				raise Inferno::Exceptions::SkipException.new(message)
			end 
		end 

		return line_count
	end 

	# TODO: Documentation
	def output_conforms_to_profile?(resource_type, metadata)
		skip 'Could not verify this functionality when Bulk Status Output is not provided' unless bulk_status_output.present?
		skip 'Could not verify this functionality when requiresAccessToken is not provided' unless requires_access_token.present?
		skip 'Could not verify this functionality when Bearer Token is required and not provided' if requires_access_token && !bearer_token.present? 
														
		file_list = JSON.parse(bulk_status_output).select { |file| file['type'] == resource_type }

		skip "No #{resource_type} resource file item returned by server." if file_list.empty?

		success_count = 0

		file_list.each do |file|
			success_count += check_file_request(file, lines_to_validate.blank?, lines_to_validate.to_i, resource_type, metadata)
		end 

		pass "Successfully validated #{success_count} #{resource_type} resource(s)."
	end 
end 