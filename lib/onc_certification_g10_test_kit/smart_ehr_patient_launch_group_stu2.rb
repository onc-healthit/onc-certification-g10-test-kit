module ONCCertificationG10TestKit
  class SMARTEHRPatientLaunchGroupSTU2 < SMARTAppLaunch::EHRLaunchGroupSTU2
    title 'EHR Launch with Patient Scopes'
    description %(
      # Background

      If an application launched from an EHR requests and is granted a clinical
      scope restricted to a single patient, the EHR SHALL establish a patient in
      context.

      # Test Methodology

      Inferno will attempt an EHR Launch with a clinical scope restricted to a
      single patient and verify that a patient id is received.

      For more information on the #{title}

      * [Apps that launch from the
        EHR](http://hl7.org/fhir/smart-app-launch/STU2/scopes-and-launch-context.html#apps-that-launch-from-the-ehr)
    )
    id :g10_ehr_patient_launch_stu2
    run_as_group

    config(
      inputs: {
        client_id: {
          name: :ehr_patient_client_id
        },
        client_secret: {
          name: :ehr_patient_client_secret
        },
        requested_scopes: {
          name: :ehr_patient_requested_scopes,
          default: 'launch openid fhirUser offline_access patient/Patient.rs',
          locked: true
        },
        code: {
          name: :ehr_patient_code
        },
        state: {
          name: :ehr_patient_state
        },
        launch: {
          name: :ehr_patient_launch
        },
        smart_credentials: {
          name: :ehr_patient_smart_credentials
        },
        smart_authorization_url: {
          title: 'OAuth 2.0 Authorize Endpoint',
          description: 'OAuth 2.0 Authorize Endpoint provided during the EHR launch'
        },
        smart_token_url: {
          title: 'OAuth 2.0 Token Endpoint',
          description: 'OAuth 2.0 Token Endpoint provided during the EHR launch'
        }
      },
      outputs: {
        launch: { name: :ehr_patient_launch },
        code: { name: :ehr_patient_code },
        token_retrieval_time: { name: :ehr_patient_token_retrieval_time },
        state: { name: :ehr_patient_state },
        id_token: { name: :ehr_patient_id_token },
        refresh_token: { name: :ehr_patient_refresh_token },
        access_token: { name: :ehr_patient_access_token },
        expires_in: { name: :ehr_patient_expires_in },
        patient_id: { name: :ehr_patient_patient_id },
        encounter_id: { name: :ehr_patient_encounter_id },
        received_scopes: { name: :ehr_patient_received_scopes },
        intent: { name: :ehr_patient_intent },
        smart_credentials: { name: :ehr_patient_smart_credentials }
      },
      requests: {
        redirect: { name: :ehr_patient_redirect },
        token: { name: :ehr_patient_token }
      }
    )

    input_order :url,
                :ehr_patient_client_id,
                :ehr_patient_client_secret,
                :smart_authorization_url,
                :smart_token_url,
                :authorization_method

    test from: :g10_patient_context,
         config: {
           inputs: {
             patient_id: { name: :ehr_patient_patient_id },
             smart_credentials: { name: :ehr_patient_smart_credentials }
           }
         }
  end
end
