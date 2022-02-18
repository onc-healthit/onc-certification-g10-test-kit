module ONCCertificationG10TestKit
  class ResourceAccessTest < Inferno::Test
    id :g10_resource_access_test
    input :patient_id, :received_scopes

    title 'Access to resources are restricted properly based on patient-selected scope'
    description %(
      This test ensures that access to the resource is granted or denied
      based on the selection by the tester prior to the execution of the test.
      If the tester indicated that access will be granted to this resource,
      this test verifies that a search by patient in this resource does not
      result in an access denied result. If the tester indicated that access
      will be denied for this resource, this verifies that search by patient
      in the resource results in an access denied result.
    )

    def resource_group
      raise StandardError, '#resource_group must be overridden'
    end

    def search_params
      @search_params ||=
        resource_group.metadata.searches.first[:names].each_with_object({}) do |name, params|
          params[name] = search_param_value(name)
        end
    end

    def search_param_value(name)
      return patient_id if ['patient', '_id', 'subject'].include?(name)

      resource_group.metadata.search_definitions[name.to_sym][:values].first
    end

    def status_search_params
      {
        "#{status_search_param_name}": search_param_value(status_search_param_name)
      }
    end

    def status_search_param_name
      @status_search_param_name ||=
        resource_group.metadata.search_definitions.keys.find { |key| key.to_s.include? 'status' }
    end

    def status_search_param_value
      @status_search_param_value ||=
        resource_group.metadata.search_definitions[status_search_param_name][:values].first
    end

    def resource_search_test
      resource_group.tests.first
    end

    def request_should_succeed?
      true
    end

    def resource_type
      resource_search_test.properties.resource_type
    end

    run do
      skip_if patient_id.blank?, 'Patient ID not provided to test.'
      skip_if received_scopes.blank?, 'No scopes were received.'

      fhir_search(resource_type, params: search_params)

      if request_should_succeed?
        if request.status == 400 && resource_search_test.properties.possible_status_search?
          error_message = %(
            Server is expected to grant access to the resource. A search
            without a status can return an HTTP 400 status, but must also must
            include an OperationOutcome. No OperationOutcome is present in the
            body of the response.
          )
          begin
            parsed_body = JSON.parse(response[:body])
            assert parsed_body['resourceType'] == 'OperationOutcome', error_message
          rescue JSON::ParserError
            assert false, error_message
          end
          fhir_search(
            :allergy_intolerance,
            params: search_params.merge(status_search_params)
          )
        end

        assert_response_status(200)
        pass "Access expected to be granted and request properly returned #{request.status}"
      else
        message = "Bad response code: expected 403 (Forbidden) or 401 (Unauthorized), but found #{request.status}."
        assert [401, 403].include?(request.status), message
      end
    end
  end
end
