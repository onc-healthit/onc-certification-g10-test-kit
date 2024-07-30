module ONCCertificationG10TestKit
  class SmartFineGrainedScopesGroup < USCoreTestKit::USCoreV610::SmartGranularScopesGroup
    title 'SMART App Launch with fine-grained scopes'
    short_title 'SMART Launch with Fine-Grained Scopes'

    input_instructions %(
      Register Inferno as a standalone application using the following information:

      * Redirect URI: `#{SMARTAppLaunch::AppRedirectTest.config.options[:redirect_uri]}`

      Each group requires a separate set of granular scopes to be granted:

      Group 1:
      * `Condition.rs?category=http://terminology.hl7.org/CodeSystem/condition-category|encounter-diagnosis`
      * `Condition.rs?category=http://hl7.org/fhir/us/core/CodeSystem/condition-category|health-concern`
      * `Observation.rs?category=http://terminology.hl7.org/CodeSystem/observation-category|laboratory`
      * `Observation.rs?category=http://terminology.hl7.org/CodeSystem/observation-category|social-history`

      Group 2:
      * `Condition.rs?category=http://terminology.hl7.org/CodeSystem/condition-category|problem-list-item`
      * `Observation.rs?category=http://terminology.hl7.org/CodeSystem/observation-category|vital-signs`
      * `Observation.rs?category=http://terminology.hl7.org/CodeSystem/observation-category|survey`
      * `Observation.rs?category=http://hl7.org/fhir/us/core/CodeSystem/us-core-category|sdoh`
    )

    description <<~DESCRIPTION
      These tests verify that the system under test supports:

      > SMART v2 scope syntax for patient-level and user-level scopes to support
        the “permission-v2” “SMART on FHIR® Capability”, including support for
        finer-grained resource constraints using search parameters according to
        section 3.0.2.3 of the implementation specification at § 170.215(c)(2) for
        the “category” parameter for the following resources: (1) Condition
        resource with Condition sub-resources Encounter Diagnosis, Problem List,
        and Health Concern; and (2) Observation resource with Observation
        sub-resources Clinical Test, Laboratory, Social History, SDOH, Survey, and
        Vital Signs

      Prior to running these tests, first run the Single Patient API tests using
      resource-level scopes. This group contains two sets of granular scope
      tests, each of which includes a SMART Standalone Launch followed by FHIR
      API tests. The app launches require that a particular subset of the
      required granular scopes be granted. The FHIR API tests then repeat all of
      the queries from the original Single Patient API tests that were run using
      resource-level scopes, and verify that only resources matching the current
      granular scopes are returned. Each group requires a separate set of
      granular scopes to be granted:

      Group 1:
      * `Condition.rs?category=http://terminology.hl7.org/CodeSystem/condition-category|encounter-diagnosis`
      * `Condition.rs?category=http://hl7.org/fhir/us/core/CodeSystem/condition-category|health-concern`
      * `Observation.rs?category=http://terminology.hl7.org/CodeSystem/observation-category|laboratory`
      * `Observation.rs?category=http://terminology.hl7.org/CodeSystem/observation-category|social-history`

      Group 2:
      * `Condition.rs?category=http://terminology.hl7.org/CodeSystem/condition-category|problem-list-item`
      * `Observation.rs?category=http://terminology.hl7.org/CodeSystem/observation-category|vital-signs`
      * `Observation.rs?category=http://terminology.hl7.org/CodeSystem/observation-category|survey`
      * `Observation.rs?category=http://hl7.org/fhir/us/core/CodeSystem/us-core-category|sdoh`

      [Finer-grained resource constraints using search
      parameters](https://hl7.org/fhir/smart-app-launch/STU2/scopes-and-launch-context.html#finer-grained-resource-constraints-using-search-parameters)
    DESCRIPTION

    id :g10_smart_fine_grained_scopes

    def self.short_id
      '9.14'
    end

    input :url

    children.each(&:run_as_group)

    # Replace generic granular scope auth group with which allows standalone or
    # ehr launch with just the standalone launch group
    granular_scopes_group1 = children.first
    granular_scopes_group1.children[0] = granular_scopes_group1.children.first.children.first
    standalone_launch_group1 = granular_scopes_group1.children[0]
    standalone_launch_group1.required

    granular_scopes_group2 = children.last
    granular_scopes_group2.children[0] = granular_scopes_group2.children.first.children.first
    standalone_launch_group2 = granular_scopes_group2.children[0]
    standalone_launch_group2.required

    # Move the granular scope API groups to the top level
    api_group1 = granular_scopes_group1.children.pop
    api_group1.children.each do |group|
      group.children.select! { |child| child.required? }
      granular_scopes_group1.children << group
    end

    api_group2 = granular_scopes_group2.children.pop
    api_group2.children.each do |group|
      group.children.select! { |child| child.required? }
      granular_scopes_group2.children << group
    end

    # Remove OIDC and refresh token tests
    standalone_launch_group1.children.pop(2)
    standalone_launch_group2.children.pop(2)

    config(
      inputs: {
        authorization_method: {
          name: :granular_scopes_authorization_method,
          title: 'Granular Scopes Authorization Request Method'
        },
        client_auth_type: {
          name: :granular_scopes_client_auth_type,
          title: 'Granular Scopes Client Authentication Type'
        },
        received_scopes: {
          name: :standalone_received_scopes
        }
      }
    )

    granular_scopes_group1.config(
      inputs: {
        client_id: {
          name: :granular_scopes1_client_id,
          title: 'Granular Scopes Group 1 Client ID'
        },
        client_secret: {
          name: :granular_scopes1_client_secret,
          title: 'Granular Scopes Group 1 Client Secret'
        },
        requested_scopes: {
          title: 'Granular Scopes Group 1 Scopes'
        }
      }
    )

    granular_scopes_group2.config(
      inputs: {
        client_id: {
          name: :granular_scopes2_client_id,
          title: 'Granular Scopes Group 2 Client ID'
        },
        client_secret: {
          name: :granular_scopes2_client_secret,
          title: 'Granular Scopes Group 2 Client Secret'
        },
        requested_scopes: {
          title: 'Granular Scopes Group 2 Scopes'
        }
      }
    )

    input_order :url,
                :granular_scopes1_client_id,
                :requested_scopes_group1,
                :granular_scopes_authorization_method,
                :granular_scopes_client_auth_type,
                :granular_scopes1_client_secret,
                :client_auth_encryption_method,
                :granular_scopes2_client_id,
                :requested_scopes_group2,
                :granular_scopes2_client_secret,
                :use_pkce,
                :pkce_code_challenge_method,
                :patient_ids

  end
end
