module ONCCertificationG10TestKit
  class VisualInspectionAndAttestationsGroup < Inferno::TestGroup
    title 'Visual Inspection and Attestation'
    short_title 'Visual Inspection'
    description 'Verify conformance to portions of the test procedure that are not automated.'
    id :g10_visual_inspection_and_attestations
    run_as_group

    test do
      title 'Health IT Module demonstrated support for application registration for single patients.'
      description %(
        Health IT Module demonstrated support for application registration for
        single patients.
      )
      id 'Test01'
      input :single_patient_registration_supported,
            title: 'Health IT Module demonstrated support for application registration for single patients.',
            type: 'radio',
            default: 'false',
            options: {
              list_options: [
                {
                  label: 'Yes',
                  value: 'true'
                },
                {
                  label: 'No',
                  value: 'false'
                }
              ]
            }
      input :single_patient_registration_notes,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert single_patient_registration_supported == 'true',
               'Health IT Module did not demonstrate support for application registration for single patients.'
        pass single_patient_registration_notes if single_patient_registration_notes.present?
      end
    end

    test do
      title 'Health IT Module demonstrated support for application registration for multiple patients.'
      description %(
        Health IT Module demonstrated support for supports application
        registration for multiple patients.
      )
      id 'Test02'
      input :multiple_patient_registration_supported,
            title: 'Health IT Module demonstrated support for application registration for multiple patients.',
            type: 'radio',
            default: 'false',
            options: {
              list_options: [
                {
                  label: 'Yes',
                  value: 'true'
                },
                {
                  label: 'No',
                  value: 'false'
                }
              ]
            }
      input :multiple_patient_registration_notes,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert multiple_patient_registration_supported == 'true',
               'Health IT Module did not demonstrate support for application registration for multiple patients.'
        pass multiple_patient_registration_notes if multiple_patient_registration_notes.present?
      end
    end

    test do
      title 'Health IT Module demonstrated a graphical user interface for user to authorize FHIR resources.'
      description %(
        Health IT Module demonstrated a graphical user interface for user to
        authorize FHIR resources
      )
      id 'Test03'
      input :resource_authorization_gui_supported,
            title: 'Health IT Module demonstrated a graphical user interface for user to authorize FHIR resources.',
            type: 'radio',
            default: 'false',
            options: {
              list_options: [
                {
                  label: 'Yes',
                  value: 'true'
                },
                {
                  label: 'No',
                  value: 'false'
                }
              ]
            }
      input :resource_authorization_gui_notes,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert resource_authorization_gui_supported == 'true',
               'Health IT Module did not demonstrate a graphical user interface for user to authorize FHIR resources'
        pass resource_authorization_gui_notes if resource_authorization_gui_notes.present?
      end
    end

    test do
      title 'Health IT Module informed patient when "offline_access" scope is being granted during authorization.'
      description %(
        Health IT Module informed patient when "offline_access" scope is being
        granted during authorization.
      )
      id 'Test04'
      input :offline_access_notification_supported,
            title: 'Health IT Module informed patient when "offline_access" scope is being granted during authorization.', # rubocop:disable Layout/LineLength
            type: 'radio',
            default: 'false',
            options: {
              list_options: [
                {
                  label: 'Yes',
                  value: 'true'
                },
                {
                  label: 'No',
                  value: 'false'
                }
              ]
            }
      input :offline_access_notification_notes,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert offline_access_notification_supported == 'true',
               'Health IT Module did not inform patient when offline access scope ' \
               'is being granted during authorization.'
        pass offline_access_notification_notes if offline_access_notification_notes.present?
      end
    end

    test do
      title 'Health IT Module attested that it is capable of issuing refresh tokens ' \
            'that are valid for a period of no shorter than three months.'
      description %(
        Health IT Module attested that it is capable of issuing refresh tokens
        that are valid for a period of no shorter than three months.
      )
      id 'Test05'
      input :refresh_token_period_attestation,
            title: 'Health IT Module attested that it is capable of issuing refresh tokens that are valid for a period of no shorter than three months.', # rubocop:disable Layout/LineLength
            type: 'radio',
            default: 'false',
            options: {
              list_options: [
                {
                  label: 'Yes',
                  value: 'true'
                },
                {
                  label: 'No',
                  value: 'false'
                }
              ]
            }
      input :refresh_token_period_notes,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert refresh_token_period_attestation == 'true',
               'Health IT Module did not attest that it is capable of issuing refresh tokens ' \
               'that are valid for a period of no shorter than three months.'
        pass refresh_token_period_notes if refresh_token_period_notes.present?
      end
    end

    test do
      title 'Health IT developer demonstrated the ability of the Health IT Module / ' \
            'authorization server to validate token it has issued.'
      description %(
        Health IT developer demonstrated the ability of the Health IT Module /
        authorization server to validate token it has issued
      )
      id 'Test06'
      input :token_validation_support,
            title: 'Health IT developer demonstrated the ability of the Health IT Module / authorization server to validate token it has issued.', # rubocop:disable Layout/LineLength
            type: 'radio',
            default: 'false',
            options: {
              list_options: [
                {
                  label: 'Yes',
                  value: 'true'
                },
                {
                  label: 'No',
                  value: 'false'
                }
              ]
            }
      input :token_validation_notes,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert token_validation_support == 'true',
               'Health IT Module did not demonstrate the ability of the Health IT Module / ' \
               'authorization server to validate token it has issued'
        pass token_validation_notes if token_validation_notes.present?
      end
    end

    test do
      title 'Tester verifies that all information is accurate and without omission.'
      description %(
        Tester verifies that all information is accurate and without omission.
      )
      id 'Test07'
      input :information_accuracy_attestation,
            title: 'Tester verifies that all information is accurate and without omission.',
            type: 'radio',
            default: 'false',
            options: {
              list_options: [
                {
                  label: 'Yes',
                  value: 'true'
                },
                {
                  label: 'No',
                  value: 'false'
                }
              ]
            }
      input :information_accuracy_notes,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert information_accuracy_attestation == 'true',
               'Tester did not verify that all information is accurate and without omission.'
        pass information_accuracy_notes if information_accuracy_notes.present?
      end
    end

    test do
      title 'Information returned no greater than scopes pre-authorized for multi-patient queries.'
      description %(
        Information returned no greater than scopes pre-authorized for
        multi-patient queries.
      )
      id 'Test08'
      input :multi_patient_scopes_attestation,
            title: 'Information returned no greater than scopes pre-authorized for multi-patient queries.',
            type: 'radio',
            default: 'false',
            options: {
              list_options: [
                {
                  label: 'Yes',
                  value: 'true'
                },
                {
                  label: 'No',
                  value: 'false'
                }
              ]
            }
      input :multi_patient_scopes_notes,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert multi_patient_scopes_attestation == 'true',
               'Tester did not verify that all information is accurate and without omission.'
        pass multi_patient_scopes_notes if multi_patient_scopes_notes.present?
      end
    end

    test do
      title 'Health IT developer demonstrated the documentation is available at a publicly accessible URL.'
      description %(
        Health IT developer demonstrated the documentation is available at a
        publicly accessible URL.
      )
      id 'Test09'
      input :developer_documentation_attestation,
            title: 'Health IT developer demonstrated the documentation is available at a publicly accessible URL.',
            type: 'radio',
            default: 'false',
            options: {
              list_options: [
                {
                  label: 'Yes',
                  value: 'true'
                },
                {
                  label: 'No',
                  value: 'false'
                }
              ]
            }
      input :developer_documentation_notes,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert developer_documentation_attestation == 'true',
               'Health IT developer did not demonstrate the documentation is available at a publicly accessible URL.'
        pass developer_documentation_notes if developer_documentation_notes.present?
      end
    end

    test do
      title 'Health IT developer confirms the Health IT module does not cache the JWK Set received ' \
            'via a TLS-protected URL for longer than the cache-control header received by an application indicates.'
      description %(
        The Health IT developer confirms the Health IT module does not cache the
        JWK Set received via a TLS-protected URL for longer than the
        cache-control header indicates.
      )
      id 'Test10'
      input :jwks_cache_attestation,
            title: 'Health IT developer confirms the Health IT module does not cache the JWK Set received via a TLS-protected URL for longer than the cache-control header indicates.', # rubocop:disable Layout/LineLength
            type: 'radio',
            default: 'false',
            options: {
              list_options: [
                {
                  label: 'Yes',
                  value: 'true'
                },
                {
                  label: 'No',
                  value: 'false'
                }
              ]
            }
      input :jwks_cache_notes,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert jwks_cache_attestation == 'true',
               'Health IT developer did not confirm that the JWK Sets are not cached for longer than appropriate.'
        pass jwks_cache_notes if jwks_cache_notes.present?
      end
    end

    test do
      title 'Health IT developer demonstrates support for the Patient Demographics Suffix USCDI v1 element.'
      description %(
        ONC certification criteria states that all USCDI v1 data classes and
        elements need to be supported, including Patient Demographics -
        Suffix.However, US Core v3.1.1 does not tag the relevant element
        (Patient.name.suffix) as MUST SUPPORT. The Health IT developer must
        demonstrate support for this USCDI v1 element as described in the US
        Core Patient Profile implementation guidance.
      )
      id 'Test11'

      if Feature.us_core_v4?
        required_suite_options us_core_version: 'us_core_3'
      end

      input :patient_suffix_attestation,
            title: 'Health IT developer demonstrates support for the Patient Demographics Suffix USCDI v1 element.',
            type: 'radio',
            default: 'false',
            options: {
              list_options: [
                {
                  label: 'Yes',
                  value: 'true'
                },
                {
                  label: 'No',
                  value: 'false'
                }
              ]
            }
      input :patient_suffix_notes,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert patient_suffix_attestation == 'true',
               'Health IT developer did not demonstrate that Patient Demographics Suffix is supported.'
        pass patient_suffix_notes if patient_suffix_notes.present?
      end
    end

    test do
      title 'Health IT developer demonstrates support for the Patient Demographics Previous Name USCDI v1 element.'
      description %(
        ONC certification criteria states that all USCDI v1 data classes and
        elements need to be supported, including Patient Demographics - Previous
        Name. However, US Core v3.1.1 does not tag the relevant element
        (Patient.name.period) as MUST SUPPORT. The Health IT developer must
        demonstrate support for this USCDI v1 element as described in the US
        Core Patient Profile implementation guidance.
      )
      id 'Test12'

      if Feature.us_core_v4?
        required_suite_options us_core_version: 'us_core_3'
      end

      input :patient_previous_name_attestation,
            title: 'Health IT developer demonstrates support for the Patient Demographics Previous Name USCDI v1 element.', # rubocop:disable Layout/LineLength
            type: 'radio',
            default: 'false',
            options: {
              list_options: [
                {
                  label: 'Yes',
                  value: 'true'
                },
                {
                  label: 'No',
                  value: 'false'
                }
              ]
            }
      input :patient_previous_name_notes,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert patient_previous_name_attestation == 'true',
               'Health IT developer did not demonstrate that Patient Demographics Previous Name is supported.'
        pass patient_previous_name_notes if patient_previous_name_notes.present?
      end
    end

    test do
      title 'Health IT developer demonstrates support for issuing refresh tokens to native applications.'
      description %(
        The health IT developer demonstrates the ability of the Health IT Module
        to grant a refresh token valid for a period of no less than three months
        to native applications capable of storing a refresh token.

        This cannot be tested in an automated way because the health IT
        developer may require use of additional security mechanisms within the
        OAuth 2.0 authorization flow to ensure authorization is sufficiently
        secure for native applications.
      )
      id 'Test13'
      input :native_refresh_attestation,
            title: 'Health IT developer demonstrates support for issuing refresh tokens to native applications.',
            type: 'radio',
            default: 'false',
            options: {
              list_options: [
                {
                  label: 'Yes',
                  value: 'true'
                },
                {
                  label: 'No',
                  value: 'false'
                }
              ]
            }
      input :native_refresh_notes,
            title: 'Notes, if applicable:',
            type: 'textarea',
            optional: true

      run do
        assert native_refresh_attestation == 'true',
               'Health IT developer did not demonstrate support for issuing refresh tokens to native applications.'
        pass native_refresh_notes if native_refresh_notes.present?
      end
    end
  end
end
