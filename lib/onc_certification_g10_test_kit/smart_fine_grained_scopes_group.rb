module ONCCertificationG10TestKit
  class SmartFineGrainedScopesGroup < USCoreTestKit::USCoreV610::SmartGranularScopesGroup
    title 'SMART App Launch with fine-grained scopes'
    short_title 'SMART Launch with Fine-Grained Scopes'

    # input_instructions %(
    #   Register Inferno as a standalone application using the following information:

    #   * Redirect URI: `#{SMARTAppLaunch::AppRedirectTest.config.options[:redirect_uri]}`

    #   Enter in the appropriate v1 scopes to enable patient-level access to all
    #   relevant resources. In addition, support for the OpenID Connect (openid
    #   fhirUser), refresh tokens (offline_access), and patient context
    #   (launch/patient) are required.
    # )

    # description %(
    #     This scenario demonstrates the ability of a system to perform a
    #     Standalone Launch with v1 scopes, and then performs simple queries te
    #     ensure that access is granted to all resources.

    #     > For backwards compatibility with scopes defined in the SMART App
    #       Launch 1.0 specification, servers SHOULD advertise the permission-v1
    #       capability in their .well-known/smart-configuration discovery
    #       document, SHOULD return v1 scopes when v1 scopes are requested and
    #       granted, and SHOULD process v1 scopes with the following semantics in
    #       v2:

    #     > * v1 .read ⇒ v2 .rs

    #     [SMART on FHIR Scopes for requesting FHIR Resources
    #       (STU2)](http://hl7.org/fhir/smart-app-launch/scopes-and-launch-context.html#scopes-for-requesting-fhir-resources)
    #   )
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
    granular_scopes_group1.children[0].required

    granular_scopes_group2 = children.last
    granular_scopes_group2.children[0] = granular_scopes_group2.children.first.children.first
    granular_scopes_group2.children[0].required

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

    config(
      inputs: {
        authorization_method: {
          name: :granular_scopes_authorization_method,
          title: 'Granular Scopes Authorization Request Method'
        },
        client_auth_type: {
          name: :granular_scopes_client_auth_type,
          title: 'Granular Scopes Client Authentication Type'
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
