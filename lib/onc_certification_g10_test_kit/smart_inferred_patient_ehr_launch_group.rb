module ONCCertificationG10TestKit
  class SMARTInferredPatientEHRLaunchGroup < SMARTAppLaunch::EHRLaunchGroupSTU2
    title 'Inferred Patient EHR Launch'
    description %(
      # Background

      If an application launched from an EHR requests and is granted
      a clinical scope restricted to a single patient, the EHR SHALL establish a patient in context.

      # Test Methodology

      Inferno will attempt an EHR Launch with a clnical scope restricted to a single patient.

      For more information on the #{title}

      * [Apps that launch from the EHR](http://hl7.org/fhir/smart-app-launch/scopes-and-launch-context.html#apps-that-launch-from-the-ehr)
    )
    id :g10_inferred_patient_ehr_launch
    run_as_group

    config(
      inputs: {
        client_id: {
          name: :inferred_client_id
        },
        client_secret: {
          name: :inferred_client_secret
        },
        requested_scopes: {
          name: :inferred_requested_scopes
        },
        code: {
          name: :inferred_code
        },
        state: {
          name: :inferred_state
        },
        launch: {
          name: :inferred_launch
        },
        smart_credentials: {
          name: :inferred_smart_credentials
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
        launch: { name: :inferred_launch },
        code: { name: :inferred_code},
        token_retrieval_time: { name: :inferred_token_retrieval_time },
        state: { name: :inferred_state },
        id_token: { name: :inferred_id_token },
        refresh_token: { name: :inferred_refresh_token },
        access_token: { name: :inferred_access_token },
        expires_in: { name: :inferred_expires_in },
        patient_id: { name: :inferred_patient_id },
        encounter_id: { name: :inferred_encounter_id },
        received_scopes: { name: :inferred_received_scopes },
        intent: { name: :inferred_intent },
        smart_credentials: { name: :inferred_smart_credentials }
      },
      requests: {
        redirect: { name: :inferred_redirect },
        token: { name: :inferred_token }
      }
    )

    input_order :url,
                :inferred_client_id,
                :inferred_client_secret,
                :smart_authorization_url,
                :smart_token_url,
                :authorization_method

    test from: :g10_patient_context,
         config: {
           inputs: {
             patient_id: { name: :inferred_patient_id },
             smart_credentials: { name: :inferred_smart_credentials }
           }
         }
  end
end
