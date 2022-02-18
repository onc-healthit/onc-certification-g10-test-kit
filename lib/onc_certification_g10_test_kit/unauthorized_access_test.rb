module ONCCertificationG10TestKit
  class UnauthorizedAccessTest < Inferno::Test
    title 'Server rejects unauthorized access'
    description %(
      A server SHALL reject any unauthorized requests by returning an HTTP 401
      unauthorized response code.
    )
    id :g10_unauthorized_access
    input :patient_id, :url
    uses_request :token

    fhir_client :unauthenticated do
      url :url
    end

    run do
      skip_if request.status != 200, 'Token exchange was unsuccessful'
      skip_if patient_id.blank?, 'Patient context expected to verify unauthorized read.'

      fhir_read(:patient, patient_id, client: :unauthenticated)

      assert_response_status(401)
    end
  end
end
