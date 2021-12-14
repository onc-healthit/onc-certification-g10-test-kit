require 'pry'
module BulkDataUtils

	include Inferno::DSL::Assertions

	VERSION = 'R4'
	NON_US_CORE_KLASS = ['Location'].freeze
	MAX_NUM_RECENT_LINES = 100
	MIN_RESOURCE_COUNT = 2

	attr_accessor :patient_ids_seen

	@@patient_ids_seen = []

	def self.included(klass)
		
	end 

	# Locally stored JWK related code i.e. pulling from  bulk_data_jwks.json.
	# Takes an encryption method as a string and filters for the corresponding
	# key. The :bulk_encryption_method symbol was not recognized from within the
	# scope of this method, hence why its passed as a parameter.
	#
	# In program, this information was set within the config.yml file and related
	# methods written within the testing_instance.rb file. The following
	# code cherry picks what was needed from those files, but we should probably
	# make an organizational decision about where this stuff will live.
	def get_bulk_selected_private_key(encryption)
		bulk_data_jwks = JSON.parse(File.read(File.join(File.dirname(__FILE__), 'bulk_data_jwks.json')))
		bulk_private_key_set = bulk_data_jwks['keys'].select { |key| key['key_ops']&.include?('sign') }
		bulk_private_key_set.find { |key| key['alg'] == encryption }
	end

	# TODO: Clean up params
	def create_client_assertion(encryption_method:, iss:, sub:, aud:, exp:, jti:)
		bulk_private_key = get_bulk_selected_private_key(encryption_method)
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
		headers.merge!( { authorization: "Bearer #{bulk_access_token}" } ) if use_token 

		# TODO: Do I need to use defined? or can I just check its existence as-is
		id = defined?(group_id) ? group_id : 'example'
		get("Group/#{id}/$export", client: :bulk_server, name: :export, headers: headers)
	end

	def check_export_status(timeout)

		wait_time = 1
		start = Time.now

		begin
			get(client: :polling_location, headers: { authorization: "Bearer #{bulk_access_token}"})

			retry_after = (response[:headers].find { |header| header.name == 'retry-after' })
			retry_after_val = retry_after.nil? || retry_after.value.nil? ? 0 : retry_after.value.to_i
			wait_time = retry_after_val.positive? ? retry_after_val : wait_time *= 2

			timeout -= Time.now - start + wait_time
			sleep wait_time

		end while response[:status] == 202 and timeout > 0

	end 






	## GROUP 3







	def get_file(endpoint, use_token = true)
		headers = { accept: 'application/fhir+ndjson' }
		headers.merge!({ authorization: "Bearer #{bulk_access_token}" }) if use_token

	 	get(endpoint, headers: headers)
	end 

	# Responsibility falls on the process_chunk block to check whether the input
	# line is nil or empty. 
	# Observation: chunk_by_lines may very well be a singleton array of a MASSIVE resource that is incomplete. 
	# The responsibility of dealing with that should fall on process_chunk_line
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

		stream(endpoint, process_body, headers: headers)
		process_chunk_line.call(hanging_chunk)

		# TODO --> Would lijke for this block to get called once during the 
		#					 block above so that we can check what the response is 
		#					 and opt out if its bad or if the headers aren't what we
		#					 need.
		process_response.call(response) 

	end

	def predefined_device_type?(resource)  
		return false if resource.nil?


	end 

	# TODO: Deal with device and lab edge cases
	# Returns the canonical url denoting the profile
	def determine_profile(profile_definitions, resource)

		return profile_definitions[0][:profile] unless profile_definitions[0][:profile].nil?

		assert false, "Profile for #{resource.class.name.demodulize} could not be determined." 

		#return nil if resource.resourceType == 'Device' && !predefined_device_type?(resource)
		#return nil if NON_US_CORE_KLASS.include(resource.resourceType)

		#Inferno::ValidationUtil.guess_profile(resource, @version)
	end 

	# DFS of a resource. Intended to be called only as a helper from within 
	#	resolve_element_from_path.
	def walk_resource(resource, steps, block)
		return block.call(resource) if steps.empty?
		return false if resource.nil? 
			
		return (resource.find { |elem| walk_resource(elem, steps, block) } || false) if resource.is_a?(Array)

		resource.respond_to?(steps.first.to_sym) ? walk_resource(resource.send(steps.first.to_sym), steps.drop(1), block) : false
	end 

	# Searches resource for the element maintained at the end of the path. 
	#
	# @param resource [FHIR Resource]
	# @param path [String] String concatenation of valid, nested attributes of 
	#											 the given resource type.	Steps in the path must be 
	#											 delimited by '.'
	# @output [Boolean] Result of applying the given block to the found element.
	#										The given block must return a boolean. If no block given,
	#										true is returned if path is walkable within the resource.
	def resolve_element_from_path(resource, path)
		return false if path.nil?
		return false unless path.respond_to?(:split)

		steps = path.split('.') 
		steps.delete_if { |step| step.empty? }

		block = proc { |element| block_given? ? yield(element) : true }
		walk_resource(resource, steps, block)
	end 

	def find_slice_by_values(element, values)
		unique_first_part = values.map { |value_def| value_def[:path].first }.uniq
		Array.wrap(element).find do |el|
			unique_first_part.all? do |part|
				values_matching = values.select { |value_def| value_def[:path].first == part }
				values_matching.each { |value_def| value_def[:path] = value_def[:path].drop(1) }
				resolve_element_from_path(el, part) do |el_found|
					all_matches = values_matching.select { |value_def| value_def[:path].empty? }.all? { |value_def| value_def[:value] == el_found }
					remaining_values = values_matching.reject { |value_def| value_def[:path].empty? }
					remaining_matches = remaining_values.present? ? find_slice_by_values(el_found, remaining_values) : true
					all_matches && remaining_matches
				end
			end
		end
	end

	def find_slice(resource, path, discriminator)
		resolve_element_from_path(resource, path) do |list|
			case discriminator[:type]
			when 'patternCodeableConcept'
				code_path = [discriminator[:path], 'coding'].join('.')
				resolve_element_from_path(list, code_path) do |coding|
					coding.code == discriminator[:code] && coding.system == discriminator[:system]
				end 
			when 'patternIdentifier'
				resolve_element_from_path(list, discriminator[:path]) do |identifier|
					identifier.system == discriminator[:system]
				end 
			when 'value'
				values_clone = discriminator[:values].deep_dup
				values_clone.each { |value| value[:path] = value[:path].split('.') }
				find_slice_by_values(list, values_clone)
			when 'type'
				case discriminator[:code]
				when 'Date'
					begin
						Date.parse(list)
					rescue ArgumentError
						false
					end 
				when 'String'
					list.is_a? String
				else
					list.is_a? FHIR.const_get(discriminator[:code])
				end 
			end 
		end
	end 

	def process_must_support(must_support_info, resource)
		return if must_support_info.nil?

		must_support_info[:elements].reject! do |ms_elem|
			resolve_element_from_path(resource, ms_elem[:path]) do |value|
				value.to_hash.reject! { |key, _| key == 'extension' } if value.respond_to?(:to_hash)
				(value.present? || !value) && (ms_elem[:fixed_value].nil? || value == ms_elem[:fixed_value]) 
			end 
		end 

		must_support_info[:extensions].reject! do |ms_extension|
			resource.extension.any? { |extension| extension.url == ms_extension[:url] }
		end

		must_support_info[:slices].reject! do |ms_slice|
			find_slice(resource, ms_slice[:path], ms_slice[:discriminator])
		end
	end 

	def process_profile_definition(profile_definitions, profile_url, resource)
		return if profile_definitions.empty? 

		profile_definition = profile_definitions.find { |prof_def| prof_def[:profile] == profile_url } || profile_definitions.first
		process_must_support(profile_definition[:must_support_info], resource)
	end 

	def assert_must_supports_found(profile_definitions)
		profile_definitions.each do |must_support|
			error_string = "Could not verify presence#{' for profile ' + must_support[:profile] if must_support[:profile].present?} of the following must support %s: %s"
			missing_must_supports = must_support[:must_support_info]

			missing_elements_list = missing_must_supports[:elements].map { |el| "#{el[:path]}#{': ' + el[:fixed_value] if el[:fixed_value].present?}" }
			skip_if missing_elements_list.present?, format(error_string, 'elements', missing_elements_list.join(', '))

			missing_slices_list = missing_must_supports[:slices].map { |slice| slice[:name] }
			skip_if missing_slices_list.present?, format(error_string, 'slices', missing_slices_list.join(', '))

			missing_extensions_list = missing_must_supports[:extensions].map { |extension| extension[:id] }
			skip_if missing_extensions_list.present?, format(error_string, 'extensions', missing_extensions_list.join(', '))
		end
	end

	# Use stream_ndjson to keep pulling chunks off the response body as they come in
	# lots of unclear if statements based off lines to validate --> investigate this
		#
	# For each chunk read in, get the resource and record the id of whether it is a patient 
	#	
	def check_file_request(file, 
												 klass, 
												 validate_all, 
												 lines_to_validate, 
												 profile_definitions)

		headers = { accept: 'application/fhir+ndjson' }
		headers.merge!( { authorization: "Bearer #{bulk_access_token}" } ) if requires_access_token
												 
		recent_resources = []
		incomplete_resource = String.new
		line_count = 0

		# TODO: Tidy this up. It's disjointed. 
		process_line = proc { |resource|
			break unless validate_all || line_count < lines_to_validate || (klass == 'Patient' && @@patient_ids_seen.length < MIN_RESOURCE_COUNT)
			next if resource.nil? || resource.strip.empty?

			recent_resources << resource unless line_count >= MAX_NUM_RECENT_LINES
			line_count += 1
			
			begin 
				resource = FHIR.from_contents(resource)
			rescue 
				assert false, "Server response at line \"#{line_count}\" is not a processable FHIR resource."
			end 

			resource_type = resource.class.name.demodulize
			assert resource_type == klass, "Resource type \"#{resource_type}\" at line \"#{line_count}\" does not match type defined in output \"#{klass}\")"
			
			@@patient_ids_seen << resource.id if klass == 'Patient'

			profile_url = determine_profile(profile_definitions, resource)
			assert resource_is_valid?(resource: resource, profile_url: profile_url), invalid_resource_message(profile_url)

			process_profile_definition(profile_definitions, profile_url, resource)			
		}

		process_headers = proc { |response| 
			header = response[:headers].find { |header| header.name.downcase == 'content-type' }
			value = header.value || 'type left unspecified.'
			assert value.start_with?('application/fhir+ndjson'), "Content type must have 'application/fhir+ndjson' but found '#{value}'"
		}

		stream_ndjson(file['url'], headers, process_line, process_headers)

		assert_must_supports_found(profile_definitions)

		if validate_all && file.key?('count')
			warning do
				assert file['count'].to_s == line_count.to_s, "Count in status output (#{file['count']}) did not match actual number of resources returned (#{line_count})"
			end
		end 

		line_count
	end 

	# Determine whether the file items in bulk_status_output contain resources 
	#	that conform to the given profiles. 
	# 
	# @param klass [FHIR ResourceType] 
	# @param profile_definitions []
	# @param lines_to_validate [Integer] must be an integer greater than or equal to 1
	# @param validate_all [Boolean] 
	def output_conforms_to_profile?(klass, 
																	profile_definitions = [], 
																	lines_to_validate = 100,
																	validate_all = false)
		
		skip 'Could not verify this functionality when bulk_status_output is not provided' unless bulk_status_output.present?
		skip 'Could not verify this functionality when requires_access_token is not set' unless requires_access_token.present?
		skip 'Could not verify this functionality when remote_access_token is required and not provided' if requires_access_token && !bulk_access_token.present? 
														
		assert_valid_json(bulk_status_output)

		file_list = JSON.parse(bulk_status_output).select { |file| file['type'] == klass }

		skip "No #{klass} resource file item returned by server." if file_list.empty?

		success_count = 0
				
		file_list.each do |file|
			success_count += check_file_request(file, klass, validate_all, lines_to_validate, profile_definitions)
		end 

		return !success_count.zero? 
	end 
end 