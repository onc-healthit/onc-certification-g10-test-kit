module InfernoTemplate
  class PatientGroup < Inferno::TestGroup
    title 'Patient  Tests'
    description 'Verify that the server makes Patient resources available'
    id :patient_group

    test do
      title 'Server returns requested Patient resource from the Patient read interaction'
      description %(
        Verify that Patient resources can be read from the server.
      )

      input :patient_id
      # Named requests can be used by other tests
      makes_request :patient

      run do
        fhir_read(:patient, patient_id, name: :patient)

        assert_response_status(200)
        assert_resource_type(:patient)
        assert resource.id == patient_id,
               "Requested resource with id #{patient_id}, received resource with id #{resource.id}"
      end
    end

    test do
      title 'Patient resource is valid'
      description %(
        Verify that the Patient resource returned from the server is a valid FHIR resource.
      )
      # This test will use the response from the :patient request in the
      # previous test
      uses_request :patient

      run do
        assert_valid_resource
      end
    end
  end
end
