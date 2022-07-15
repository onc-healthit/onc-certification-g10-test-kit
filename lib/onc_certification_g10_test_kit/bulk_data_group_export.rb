require_relative 'export_kick_off_performer'

module ONCCertificationG10TestKit
  class BulkDataGroupExport < Inferno::TestGroup
    id :bulk_data_group_export

    input :bearer_token
    input :bulk_server_url,
          title: 'Bulk Data FHIR URL',
          description: 'The URL of the Bulk FHIR server.'
    input :group_id,
          title: 'Group ID',
          description: 'The Group ID associated with the group of patients to be exported.'
    input :bulk_timeout,
          title: 'Export Times Out after (1-600)',
          description: <<~DESCRIPTION,
            While testing, Inferno waits for the server to complete the exporting task. If the calculated totalTime is
            greater than the timeout value specified here, Inferno bulk client stops testing. Please enter an integer
            for the maximum wait time in seconds. If timeout is less than 1, Inferno uses default value 180. If the
              timeout is greater than 600 (10 minutes), Inferno uses the maximum value 600.
          DESCRIPTION
          default: 180

    output :requires_access_token, :status_output, :bulk_download_url

    fhir_client :bulk_server do
      url :bulk_server_url
    end

    http_client :bulk_server do
      url :bulk_server_url
    end

    test from: :tls_version_test do
      title 'Bulk Data Server is secured by transport layer security'
      description <<~DESCRIPTION
        [§170.315(g)(10) Test
        Procedure](https://www.healthit.gov/test-method/standardized-api-patient-and-population-services)
        requires that all exchanges described herein between a client and a
        server SHALL be secured using Transport Layer Security (TLS) Protocol
        Version 1.2 (RFC5246).
      DESCRIPTION
      id :g10_bulk_data_server_tls_version

      config(
        inputs: { url: { name: :bulk_server_url } },
        options: { minimum_allowed_version: OpenSSL::SSL::TLS1_2_VERSION }
      )
    end

    test do
      title 'Bulk Data Server declares support for Group export operation in CapabilityStatement'
      id :export_capability_statement

      run do
        fhir_get_capability_statement(client: :bulk_server)
        assert_response_status([200, 201])

        assert_valid_json(request.response_body)
        capability_statement = FHIR.from_contents(request.response_body)

        warning do
          has_instantiates = capability_statement&.instantiates&.any? do |canonical|
            canonical.match(%r{^http://hl7.org/fhir/uv/bulkdata/CapabilityStatement/bulk-data(\|\S+)?$})
          end
          assert has_instantiates,
                 'Server did not declare conformance to the Bulk Data IG by including ' \
                 "'http://hl7.org/fhir/uv/bulkdata/CapabilityStatement/bulk-data' in " \
                 " CapabilityStatement.instantiates element (#{capability_statement&.instantiates})"
        end

        group_resource_capabilities = nil

        capability_statement&.rest&.each do |rest|
          group_resource_capabilities = rest.resource&.find do |resource|
            resource.type == 'Group'
          end
        end

        assert group_resource_capabilities.respond_to?(:operation) && group_resource_capabilities.operation&.any?,
               'Server CapabilityStatement did not declare support for any operations on the Group resource'

        has_export_operation = group_resource_capabilities.operation&.any? do |operation|
          name_match = (operation.name == 'export')
          if name_match && !operation.definition&.match(%r{^http://hl7.org/fhir/uv/bulkdata/OperationDefinition/group-export(\|\S+)?$})
            info('Server CapabilityStatement does not include export operation with definition http://hl7.org/fhir/uv/bulkdata/OperationDefinition/group-export')
          end
          name_match
        end
        warning do
          assert has_export_operation,
                 'Server CapabilityStatement did not declare support for an operation named "export" in the Group ' \
                 ' resource (operation.name should be "export")'
        end
      end
    end

    test do
      title 'Bulk Data Server rejects $export request without authorization'
      description <<~DESCRIPTION
        The FHIR server SHALL limit the data returned to only those FHIR resources for which the client is authorized.

        [FHIR R4 Security](https://www.hl7.org/fhir/security.html#AccessDenied) and
        [The OAuth 2.0 Authorization Framework: Bearer Token Usage](https://tools.ietf.org/html/rfc6750#section-3.1)
        recommend using HTTP status code 401 for invalid token but also allow the actual result be controlled by policy and context.
      DESCRIPTION
      # link 'http://hl7.org/fhir/uv/bulkdata/STU1.0.1/export/index.html#bulk-data-kick-off-request'

      id :rejects_unauthorized_export

      include ExportKickOffPerformer

      run do
        skip_if bearer_token.blank?, 'Could not verify this functionality when bearer token is not set'

        perform_export_kick_off_request(use_token: false)
        assert_response_status([400, 401])
      end
    end

    test do
      title 'Bulk Data Server returns "202 Accepted" and "Content-location" for $export operation'
      description <<~DESCRIPTION
        Response - Success

        * HTTP Status Code of 202 Accepted
        * Content-Location header with the absolute URL of an endpoint for subsequent status requests (polling location)
      DESCRIPTION
      # link 'http://hl7.org/fhir/uv/bulkdata/STU1.0.1/export/index.html#response---success'

      id :export_returns_okay_and_content_header

      include ExportKickOffPerformer

      output :polling_url

      run do
        perform_export_kick_off_request
        assert_response_status(202)

        polling_url = request.response_header('content-location')&.value
        assert polling_url.present?, 'Export response headers did not include "Content-Location"'

        output polling_url: polling_url
      end
    end

    test do
      title 'Bulk Data Server returns "202 Accepted" or "200 OK" for status check'
      description <<~DESCRIPTION
        Clients SHOULD follow an exponential backoff approach when polling for status. Servers SHOULD respond with

        * In-Progress Status: HTTP Status Code of 202 Accepted
        * Complete Status: HTTP status of 200 OK and Content-Type header of application/json

        The JSON object of Complete Status SHALL contain these required field:

        * transactionTime, request, requiresAccessToken, output, and error
      DESCRIPTION
      # link 'http://hl7.org/fhir/uv/bulkdata/STU1.0.1/export/index.html#bulk-data-status-request'

      id :status_check_returns_okay

      input :polling_url

      output :status_response, :requires_access_token

      run do
        skip 'Server response did not have Content-Location in header' unless polling_url.present?

        timeout = bulk_timeout.to_i

        if !timeout.positive?
          timeout = 180
        elsif timeout > 600
          timeout = 600
        end

        wait_time = 1
        start = Time.now

        loop do
          get(polling_url, headers: { authorization: "Bearer #{bearer_token}", accept: 'application/json' })

          retry_after_val = request.response_header('retry-after')&.value.to_i

          wait_time = retry_after_val.positive? ? retry_after_val : wait_time *= 2

          seconds_used = Time.now - start + wait_time

          break if response[:status] != 202 || seconds_used > timeout

          sleep wait_time
        end

        skip "Server took more than #{timeout} seconds to process the request." if response[:status] == 202
        assert_response_status(200)

        assert request.response_header('content-type')&.value&.include?('application/json'),
               'Content-Type not application/json'

        response_body = JSON.parse(response[:body])

        ['transactionTime', 'request', 'requiresAccessToken', 'output', 'error'].each do |key|
          assert response_body.key?(key), "Complete Status response did not contain \"#{key}\" as required"
        end

        output requires_access_token: response_body['requiresAccessToken'].to_s.downcase
        output status_response: response[:body]
      end
    end

    test do
      title 'Bulk Data Server returns output with type and url for status complete'
      description <<~DESCRIPTION
        The value of output field is an array of file items with one entry for each generated file.
        If no resources are returned from the kick-off request, the server SHOULD return an empty array.

        Each file item SHALL contain the following fields:

        * type - the FHIR resource type that is contained in the file.

        Each file SHALL contain resources of only one type, but a server MAY create more than one file for each resource type returned.

        * url - the path to the file. The format of the file SHOULD reflect that requested in the _outputFormat parameter of the initial kick-off request.
      DESCRIPTION
      # link 'http://hl7.org/fhir/uv/bulkdata/STU1.0.1/export/index.html#response---complete-status'

      id :status_complete_outputs_type_and_url

      input :status_response

      output :status_output, :bulk_download_url

      run do
        assert status_response.present?, 'Bulk Data Server status response not found'

        status_output = JSON.parse(status_response)['output']
        assert status_output, 'Bulk Data Server status response does not contain output'

        output status_output: status_output.to_json,
               bulk_download_url: status_output[0]['url']

        status_output.each do |file|
          ['type', 'url'].each do |key|
            assert file.key?(key), "Output file did not contain \"#{key}\" as required"
          end
        end
      end
    end

    test do
      title 'Bulk Data Server returns "202 Accepted" for delete request'
      description <<~DESCRIPTION
        After a bulk data request has been started, a client MAY send a delete request to the URL provided in the Content-Location header to cancel the request.
        Bulk Data Server MUST support client's delete request and return HTTP Status Code of "202 Accepted"
      DESCRIPTION
      # link 'http://hl7.org/fhir/uv/bulkdata/STU1.0.1/export/index.html#bulk-data-delete-request'

      id :delete_request_accepted

      include ExportKickOffPerformer

      run do
        perform_export_kick_off_request
        assert_response_status(202)

        delete_export_kick_off_request
      end
    end
  end
end
