require_relative 'smart_scopes_test'
require_relative 'smart_granular_scope_selection_test'

module ONCCertificationG10TestKit
  class SmartGranularScopeSelectionGroup < Inferno::TestGroup
    title 'SMART Granular Scope Selection'
    short_title 'SMART Granular Scope Selection'
    id :g10_smart_granular_scope_selection

    description <<~DESCRIPTION
      These tests verify that when resource-level scopes are requested for
      Condition and Observation resources, the user is presented with the option
      of approving sub-resource scopes rather than the resource-level scope.

      The tests request v2 resource-level Condition and Observation scopes. In
      each instance, the user must unselect the resource-level scopes and
      instead approve sub-resource scopes for Condition and Observation. It is
      also required that a resource-level Patient scope be granted.

      > As part of supporting the SMART App Launch “permission-v2” capability
        for the purposes of certification, if an app requests authorization for
        a resource level scope for the “Condition” or “Observation” resources,
        then for patient authorization purposes a Health IT Module must support
        presentation of the required sub-resource scopes to the patient for
        authorization. Specifically, sub-resource scopes must be presented for
        patient authorization as follows:

      > * “Condition” sub-resource scopes “Encounter Diagnosis”, “Problem List”,
          and “Health Concern” if a “Condition” resource level scope is
          requested
      > * “Observation” sub-resource scopes “Clinical Test”, “Laboratory”,
          “Social History”, “SDOH”, “Survey”, and “Vital Signs” if an
          “Observation” resource level scope is requested
    DESCRIPTION

    run_as_group

    config(
      inputs: {
        use_pkce: {
          default: 'true',
          locked: true
        },
        pkce_code_challenge_method: {
          locked: true
        },
        granular_scope_selection_authorization_method: {
          name: :granular_scope_selection_authorization_method,
          default: 'get'
        },
        client_auth_type: {
          name: :granular_scope_selection_client_auth_type,
          default: 'confidential_asymmetric'
        }
      }
    )

    group from: :smart_discovery_stu2

    group from: :smart_standalone_launch_stu2 do
      id :g10_granular_scope_selection_v2_scopes
      title 'Granular Scope Selection with v2 Scopes'

      config(
        inputs: {
          client_id: {
            name: :granular_scope_selection_v2_client_id,
            title: 'Granular Scope Selection w/v2 Scopes Client ID'
          },
          client_secret: {
            name: :granular_scope_selection_v2_client_secret,
            title: 'Granular Scope Selection w/v2 Scopes Client Secret',
            default: nil,
            optional: true
          },
          requested_scopes: {
            name: :granular_scope_selection_v2_requested_scopes,
            title: 'Granular Scope Selection v2 Scopes',
            default: %(
              launch/patient openid fhirUser offline_access patient/Condition.rs
              patient/Observation.rs patient/Patient.rs
            ).gsub(/\s{2,}/, ' ').strip
          },
          received_scopes: { name: :granular_scope_selection_v2_received_scopes }
        },
        outputs: {
          requested_scopes: { name: :granular_scope_selection_v2_requested_scopes },
          received_scopes: { name: :granular_scope_selection_v2_received_scopes }
        },
        options: {
          redirect_message_proc: proc do |auth_url|
            %(
              ### #{self.class.parent&.parent&.title}

              [Follow this link to authorize with the SMART server](#{auth_url}).

              Tests will resume once Inferno receives a request at
              `#{config.options[:redirect_uri]}` with a state of `#{state}`.
            )
          end
        }
      )

      test from: :g10_smart_scopes do
        config(
          options: {
            scope_version: :v2,
            required_scope_type: 'patient',
            required_scopes: ['openid', 'fhirUser', 'launch/patient', 'offline_access']
          }
        )

        def patient_compartment_resource_types
          ['Patient', 'Condition', 'Observation']
        end
      end

      test from: :g10_smart_granular_scope_selection
    end
  end
end
