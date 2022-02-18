require_relative 'resource_access_test'

module ONCCertificationG10TestKit
  class UnrestrictedResourceTypeAccessGroup < Inferno::TestGroup
    title 'Unrestricted Resource Type Access'
    description %(
      This test ensures that apps have full access to USCDI resources if granted
      access by the tester. The tester must grant access to the following
      resources during the SMART Launch process, and this test ensures they all
      can be accessed:

        * AllergyIntolerance
        * CarePlan
        * CareTeam
        * Condition
        * Device
        * DiagnosticReport
        * DocumentReference
        * Goal
        * Immunization
        * MedicationRequest
        * Observation
        * Procedure
        * Patient
        * Provenance
        * Encounter
        * Practitioner
        * Organization

      For each of the resource types that can be mapped to USCDI data class or
      elements, this set of tests performs a minimum number of requests to
      determine that the resource type can be accessed given the scope granted.
      In the case of the Patient resource, this test simply performs a read
      request. For other resources, it performs a search by patient that must be
      supported by the server. In some cases, servers can return an error
      message if a status search parameter is not provided. For these, the test
      will perform an additional search with the required status search
      parameter.

      This set of tests does not attempt to access resources that do not
      directly map to USCDI v1, including Encounter, Location, Organization, and
      Practitioner. It also does not test Provenance, as this resource type is
      accessed by queries through other resource types. These resources types
      are accessed in the more comprehensive Single Patient Query tests.

      However, the authorization system must indicate that access is granted to
      the Encounter, Practitioner and Organization resource types by providing
      them in the returned scopes because they are required to support the read
      interaction.
    )
    id :g10_unrestricted_resource_type_access

    input :url, :smart_credentials, :patient_id, :received_scopes
    input :smart_credentials, type: :oauth_credentials

    fhir_client do
      url :url
      oauth_credentials :smart_credentials
    end

    test do
      title 'Scope granted enables access to all US Core resource types.'
      description %(
        This test confirms that the scopes granted during authorization are
        sufficient to access all relevant US Core resources.
      )

      def all_resources
        [
          'AllergyIntolerance',
          'CarePlan',
          'CareTeam',
          'Condition',
          'Device',
          'DiagnosticReport',
          'DocumentReference',
          'Goal',
          'Immunization',
          'MedicationRequest',
          'Observation',
          'Procedure',
          'Patient',
          'Provenance',
          'Encounter',
          'Practitioner',
          'Organization'
        ]
      end

      def non_patient_compartment_resources
        [
          'Encounter',
          'Device',
          'Location',
          'Medication',
          'Organization',
          'Practitioner',
          'PractitionerRole',
          'RelatedPerson'
        ]
      end

      def scope_granting_access?(resource_type)
        received_scopes.split.find do |scope|
          return true if non_patient_compartment_resources.include?(resource_type) &&
                         ["user/#{resource_type}.read", "user/#{resource_type}.*"].include?(scope)

          [
            'patient/*.read',
            'patient/*.*',
            "patient/#{resource_type}.read",
            "patient/#{resource_type}.*"
          ].include?(scope)
        end
      end

      run do
        skip_if received_scopes.blank?, 'A list of granted scopes was not provided to this test as required.'

        allowed_resources = all_resources.select { |resource_type| scope_granting_access?(resource_type) }
        denied_resources = all_resources - allowed_resources

        assert denied_resources.empty?, %(
          This test requires access to all US Core resources with patient
          information, but the received scope:



          `#{received_scopes}`



          does not grant access to the `#{denied_resources.join(', ')}` resource
          type(s).
        )

        pass 'Scopes received indicate access to all necessary resources.'
      end
    end

    test from: :g10_resource_access_test do
      title 'Access to Patient resources granted'
      description %(
        This test ensures that access to the Patient is granted or
        denied based on the selection by the tester prior to the execution of
        the test. If the tester indicated that access will be granted to this
        resource, this test verifies that a search by patient in this resource
        does not result in an access denied result. If the tester indicated that
        access will be denied for this resource, this verifies that search by
        patient in the resource results in an access denied result.
      )
      id :g10_patient_unrestricted_access

      def resource_group
        USCore::PatientGroup
      end
    end

    test from: :g10_resource_access_test do
      title 'Access to AllergyIntolerance resources granted'
      description %(
        This test ensures that access to the AllergyIntolerance is granted or
        denied based on the selection by the tester prior to the execution of
        the test. If the tester indicated that access will be granted to this
        resource, this test verifies that a search by patient in this resource
        does not result in an access denied result. If the tester indicated that
        access will be denied for this resource, this verifies that search by
        patient in the resource results in an access denied result.
      )
      id :g10_allergy_intolerance_unrestricted_access

      def resource_group
        USCore::AllergyIntoleranceGroup
      end
    end

    test from: :g10_resource_access_test do
      title 'Access to CarePlan resources granted'
      description %(
        This test ensures that access to the CarePlan is granted or
        denied based on the selection by the tester prior to the execution of
        the test. If the tester indicated that access will be granted to this
        resource, this test verifies that a search by patient in this resource
        does not result in an access denied result. If the tester indicated that
        access will be denied for this resource, this verifies that search by
        patient in the resource results in an access denied result.
      )
      id :g10_care_plan_unrestricted_access

      def resource_group
        USCore::CarePlanGroup
      end
    end

    test from: :g10_resource_access_test do
      title 'Access to CareTeam resources granted'
      description %(
        This test ensures that access to the CareTeam is granted or
        denied based on the selection by the tester prior to the execution of
        the test. If the tester indicated that access will be granted to this
        resource, this test verifies that a search by patient in this resource
        does not result in an access denied result. If the tester indicated that
        access will be denied for this resource, this verifies that search by
        patient in the resource results in an access denied result.
      )
      id :g10_care_team_unrestricted_access

      def resource_group
        USCore::CareTeamGroup
      end
    end

    test from: :g10_resource_access_test do
      title 'Access to Condition resources granted'
      description %(
        This test ensures that access to the Condition is granted or
        denied based on the selection by the tester prior to the execution of
        the test. If the tester indicated that access will be granted to this
        resource, this test verifies that a search by patient in this resource
        does not result in an access denied result. If the tester indicated that
        access will be denied for this resource, this verifies that search by
        patient in the resource results in an access denied result.
      )
      id :g10_condition_unrestricted_access

      def resource_group
        USCore::ConditionGroup
      end
    end

    test from: :g10_resource_access_test do
      title 'Access to Device resources granted'
      description %(
        This test ensures that access to the Device is granted or
        denied based on the selection by the tester prior to the execution of
        the test. If the tester indicated that access will be granted to this
        resource, this test verifies that a search by patient in this resource
        does not result in an access denied result. If the tester indicated that
        access will be denied for this resource, this verifies that search by
        patient in the resource results in an access denied result.
      )
      id :g10_device_unrestricted_access

      def resource_group
        USCore::DeviceGroup
      end
    end

    test from: :g10_resource_access_test do
      title 'Access to DiagnosticReport resources granted'
      description %(
        This test ensures that access to the DiagnosticReport is granted or
        denied based on the selection by the tester prior to the execution of
        the test. If the tester indicated that access will be granted to this
        resource, this test verifies that a search by patient in this resource
        does not result in an access denied result. If the tester indicated that
        access will be denied for this resource, this verifies that search by
        patient in the resource results in an access denied result.
      )
      id :g10_diagnostic_report_unrestricted_access

      def resource_group
        USCore::DiagnosticReportLabGroup
      end
    end

    test from: :g10_resource_access_test do
      title 'Access to DocumentReference resources granted'
      description %(
        This test ensures that access to the DocumentReference is granted or
        denied based on the selection by the tester prior to the execution of
        the test. If the tester indicated that access will be granted to this
        resource, this test verifies that a search by patient in this resource
        does not result in an access denied result. If the tester indicated that
        access will be denied for this resource, this verifies that search by
        patient in the resource results in an access denied result.
      )
      id :g10_document_reference_unrestricted_access

      def resource_group
        USCore::DocumentReferenceGroup
      end
    end

    test from: :g10_resource_access_test do
      title 'Access to Goal resources granted'
      description %(
        This test ensures that access to the Goal is granted or
        denied based on the selection by the tester prior to the execution of
        the test. If the tester indicated that access will be granted to this
        resource, this test verifies that a search by patient in this resource
        does not result in an access denied result. If the tester indicated that
        access will be denied for this resource, this verifies that search by
        patient in the resource results in an access denied result.
      )
      id :g10_goal_unrestricted_access

      def resource_group
        USCore::GoalGroup
      end
    end

    test from: :g10_resource_access_test do
      title 'Access to Immunization resources granted'
      description %(
        This test ensures that access to the Immunization is granted or
        denied based on the selection by the tester prior to the execution of
        the test. If the tester indicated that access will be granted to this
        resource, this test verifies that a search by patient in this resource
        does not result in an access denied result. If the tester indicated that
        access will be denied for this resource, this verifies that search by
        patient in the resource results in an access denied result.
      )
      id :g10_immunization_unrestricted_access

      def resource_group
        USCore::ImmunizationGroup
      end
    end

    test from: :g10_resource_access_test do
      title 'Access to MedicationRequest resources granted'
      description %(
        This test ensures that access to the MedicationRequest is granted or
        denied based on the selection by the tester prior to the execution of
        the test. If the tester indicated that access will be granted to this
        resource, this test verifies that a search by patient in this resource
        does not result in an access denied result. If the tester indicated that
        access will be denied for this resource, this verifies that search by
        patient in the resource results in an access denied result.
      )
      id :g10_medication_request_access

      def resource_group
        USCore::MedicationRequestGroup
      end
    end

    test from: :g10_resource_access_test do
      title 'Access to Observation resources granted'
      description %(
        This test ensures that access to the Observation is granted or
        denied based on the selection by the tester prior to the execution of
        the test. If the tester indicated that access will be granted to this
        resource, this test verifies that a search by patient in this resource
        does not result in an access denied result. If the tester indicated that
        access will be denied for this resource, this verifies that search by
        patient in the resource results in an access denied result.
      )
      id :g10_observation_unrestricted_access

      def resource_group
        USCore::PulseOximetryGroup
      end
    end

    test from: :g10_resource_access_test do
      title 'Access to Procedure resources granted'
      description %(
        This test ensures that access to the Procedure is granted or
        denied based on the selection by the tester prior to the execution of
        the test. If the tester indicated that access will be granted to this
        resource, this test verifies that a search by patient in this resource
        does not result in an access denied result. If the tester indicated that
        access will be denied for this resource, this verifies that search by
        patient in the resource results in an access denied result.
      )
      id :g10_procedure_unrestricted_access

      def resource_group
        USCore::ProcedureGroup
      end
    end
  end
end
