module ONCCertificationG10TestKit
  class SMARTInvalidLaunchGroup < Inferno::TestGroup
    title 'SMART App Launch Error: Invalid Launch Parameter'
    short_title 'SMART Invalid Launch Parameter'
    input_instructions %(
      Register Inferno as an EHR-launched application using the following information:

      * Launch URI: `#{SMARTAppLaunch::AppLaunchTest.config.options[:launch_uri]}`
      * Redirect URI: `#{SMARTAppLaunch::AppRedirectTest.config.options[:redirect_uri]}`
    )
    description %(
      # Background

      The Invalid Launch Parameter Sequence verifies that a SMART Launch
      Sequence, specifically the [EHR
      Launch](http://www.hl7.org/fhir/smart-app-launch/#ehr-launch-sequence)
      Sequence, does not work in the case where the client sends an invalid FHIR
      server as the `launch` parameter during launch. This must fail to ensure
      that a genuine bearer token is not leaked to a counterfit resource server.

      This test is not included as part of a regular SMART Launch Sequence
      because it requires the browser of the user to be redirected to the
      authorization service, and there is no expectation that the authorization
      service redirects the user back to Inferno with an error message. The only
      requirement is that Inferno is not granted a code to exchange for a valid
      access token. Since this is a special case, it is tested independently in
      a separate sequence.
    )
    id :g10_smart_invalid_launch_param
    run_as_group

    config(
      inputs: {
        client_id: {
          name: :ehr_client_id,
          title: 'EHR Client ID',
          description: 'Client ID provided during registration of Inferno as an EHR launch application'
        },
        requested_scopes: {
          name: :ehr_requested_scopes,
          title: 'EHR Launch Scope',
          description: 'OAuth 2.0 scope provided by system to enable all required functionality',
          type: 'textarea',
          default: %(
            launch openid fhirUser offline_access user/Medication.read
            user/AllergyIntolerance.read user/CarePlan.read user/CareTeam.read
            user/Condition.read user/Device.read user/DiagnosticReport.read
            user/DocumentReference.read user/Encounter.read user/Goal.read
            user/Immunization.read user/Location.read
            user/MedicationRequest.read user/Observation.read
            user/Organization.read user/Patient.read user/Practitioner.read
            user/Procedure.read user/Provenance.read user/PractitionerRole.read
          ).gsub(/\s{2,}/, ' ').strip
        },
        url: {
          title: 'EHR Launch FHIR Endpoint',
          description: 'URL of the FHIR endpoint used by EHR launched applications'
        },
        smart_authorization_url: {
          title: 'OAuth 2.0 Authorize Endpoint',
          description: 'OAuth 2.0 Authorize Endpoint provided during an EHR launch'
        }
      },
      outputs: {
        state: { name: :invalid_launch_state }
      },
      requests: {
        redirect: { name: :invalid_launch_redirect }
      }
    )

    input_order :url,
                :ehr_client_id,
                :ehr_client_secret,
                :ehr_requested_scopes,
                :use_pkce,
                :pkce_code_challenge_method,
                :smart_authorization_url

    test from: :smart_app_launch
    test from: :smart_launch_received
    test from: :smart_app_redirect do
      input :client_secret,
            name: :ehr_client_secret,
            title: 'EHR Client Secret',
            description: 'Client Secret provided during registration of Inferno as an EHR launch application'

      config(
        options: { launch: 'INVALID_LAUNCH_PARAM' }
      )

      def wait_message(auth_url)
        %(
          Inferno will redirect you to an external website for authorization.
          **It is expected this will fail**. If the server does not return to
          Inferno automatically, but does provide an error message, you may
          return to Inferno and confirm that an error was presented in this
          window.

          * [Perform Invalid Launch](#{auth_url})
          * [Attest launch
            failed](#{Inferno::Application['base_url']}/custom/smart/redirect?state=#{state}&confirm_fail=true)
        )
      end
    end

    test do
      title 'Inferno client app does not receive code parameter redirect URI'
      description %(
        Inferno redirected the user to the authorization service with an invalid
        launch parameter. Inferno expects that the authorization request will
        not succeed. This can either be from the server explicitely pass an
        error, or stopping and the tester returns to Inferno to confirm that the
        server presented them a failure.
      )
      uses_request :redirect

      run do
        params = request.query_parameters

        assert params['code'].blank?,
               'Authorization has incorrectly succeeded because access code provided to Inferno.'

        pass_message =
          if params['error'].present?
            'Server redirected the user back to the app with an error.'
          elsif params['confirm_fail']
            'Tester attested that the authorization service did not succeed due to invalid AUD parameter.'
          else
            'Server redirected the user back to the app without an access code.'
          end

        pass pass_message
      end
    end
  end
end
