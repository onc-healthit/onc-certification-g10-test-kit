require 'smart_app_launch/standalone_launch_group'
require 'smart_app_launch/discovery_stu1_group'
require 'smart_app_launch/token_introspection_group'

require_relative 'g10_options'

module ONCCertificationG10TestKit
  class TokenIntrospectionGroup < SMARTAppLaunch::SMARTTokenIntrospectionGroup
    id :g10_token_introspection

    description <<~DESCRIPTION
      # Background

      OAuth 2.0 Token introspection, as described in
      [RFC-7662](https://datatracker.ietf.org/doc/html/rfc7662), allows an
      authorized resource server to query an OAuth 2.0 authorization server for
      metadata on a token. The [SMART App Launch STU2 Implementation Guide
      Section on Token
      Introspection](https://hl7.org/fhir/smart-app-launch/STU2/token-introspection.html)
      states that
      > SMART on FHIR EHRs SHOULD support token introspection, which allows a
      > broader ecosystem of resource servers to leverage authorization
      > decisions managed by a single authorization server.

      # Test Methodology

      In these tests, Inferno acts as an authorized resource server that queries
      the authorization server about an access token, rather than a client to a
      FHIR resource server as in the previous SMART App Launch tests. Ideally,
      Inferno should be registered with the authorization server as an
      authorized resource server capable of accessing the token introspection
      endpoint through client credentials, per the SMART IG recommendations.
      However, the SMART IG only formally REQUIRES "some form of authorization"
      to access the token introspection endpoint and does not specifiy any one
      specific approach. As such, the token introspection tests are broken up
      into three groups that each complete a discrete step in the token
      introspection process:

      1. **Request Access Token Group** - repeats a subset of Standalone Launch
        tests in order to receive a new access token with an authorization code
        grant.
      2. **Issue Token Introspection Request Group** - completes the
        introspection requests.
      3. **Validate Token Introspection Response Group** - validates the
        contents of the introspection responses.

      See the individual test groups for more details and guidance.
    DESCRIPTION

    input_instructions <<~INSTRUCTIONS
      If the introspection endpoint is protected, testers must enter their own
      HTTP Authorization header for the introspection request. See [RFC 7616 The
      'Basic' HTTP Authentication
      Scheme](https://datatracker.ietf.org/doc/html/rfc7617) for the most common
      approach that uses client credentials. Testers may also provide any
      additional parameters needed for their authorization server to complete
      the introspection request.

      **Note:** For both the Authorization header and request parameters, user-input
      values will be sent exactly as entered and therefore the tester must
      URI-encode any appropriate values.
    INSTRUCTIONS

    run_as_group

    input :well_known_introspection_url,
          title: 'Token Introspection Endpoint',
          description: <<~DESCRIPTION,
            The complete URL of the token introspection endpoint. This will be
            populated automatically if included in the server's discovery
            endpoint.
          DESCRIPTION
          optional: true

    input_order :url,
                :well_known_introspection_url,
                :custom_authorization_header,
                :optional_introspection_request_params,
                :standalone_client_id,
                :standalone_client_secret,
                :authorization_method,
                :use_pkce,
                :pkce_code_challenge_method,
                :standalone_requested_scopes,
                :token_introspection_auth_type,
                :client_auth_encryption_method

    config(
      inputs: {
        client_auth_type: {
          name: :token_introspection_auth_type
        }
      }
    )

    groups.first.description <<~DESCRIPTION
      These tests are perform discovery and a standalone launch in order to
      receive a new, active access token that will be provided for token
      introspection.
    DESCRIPTION

    groups[1].description <<~DESCRIPTION
      This group of tests executes the token introspection requests and ensures
      the correct HTTP response is returned but does not validate the contents
      of the token introspection response.
    DESCRIPTION

    # The token introspection tests are SMART v2 only, so they use v2 discovery
    # and launch groups. g10 needs them for SMART v1 and v2, so this sets the
    # original discovery and launch groups to only appear when using SMART v2,
    # and adds the v1 groups when using v1.

    groups.first.groups.each do |group|
      group.required_suite_options(G10Options::SMART_2_REQUIREMENT)
    end

    groups.first.group from: :smart_discovery,
                       required_suite_options: G10Options::SMART_1_REQUIREMENT

    groups.first.group from: :smart_standalone_launch,
                       required_suite_options: G10Options::SMART_1_REQUIREMENT
  end
end
