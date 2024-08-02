require_relative 'smart_scopes_test'

module ONCCertificationG10TestKit
  class SmartGranularScopeSelectionGroup < Inferno::TestGroup
    title 'SMART Granular Scope Selection'
    short_title 'SMART Granular Scope Selection'
    id :g10_smart_granular_scope_selection

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
        authorization_method: {
          name: :standalone_authorization_method,
          default: 'get',
          locked: true
        },
        client_auth_type: {
          locked: true,
          default: 'confidential_symmetric'
        }
      }
    )

    def self.short_id
      '9.15'
    end

    group from: :smart_discovery_stu2

    group from: :smart_standalone_launch_stu2 do
      id :g10_granular_scope_selection_v1_scopes
      title 'Granular Scope Selection with v1 Scopes'
      # description %(
      # )

      config(
        inputs: {
          requested_scopes: {
            name: :granular_scope_selection_v1_requested_scopes,
            default: %(
              launch/patient openid fhirUser offline_access
              patient/Condition.read patient/Observation.read
              patient/Patient.read
            ).gsub(/\s{2,}/, ' ').strip
          },
          received_scopes: { name: :granular_scope_selection_v1_received_scopes }
        },
        outputs: {
          requested_scopes: { name: :granular_scope_selection_v1_requested_scopes },
          received_scopes: { name: :granular_scope_selection_v1_received_scopes }
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
            requested_scope_version: :v1,
            required_scope_type: 'patient',
            required_scopes: ['openid', 'fhirUser', 'launch/patient', 'offline_access']
          }
        )

        def patient_compartment_resource_types
          ['Patient', 'Condition', 'Observation']
        end
      end
    end

    group from: :smart_standalone_launch_stu2 do
      id :g10_granular_scope_selection_v2_scopes
      title 'Granular Scope Selection with v2 Scopes'
      # description %(
      # )

      config(
        inputs: {
          requested_scopes: {
            name: :granular_scope_selection_v2_requested_scopes,
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
    end
  end
end
