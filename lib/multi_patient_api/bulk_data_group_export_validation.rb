require 'pry' #TODO: Remove
module MultiPatientAPI
  class BulkDataGroupExportValidation < Inferno::TestGroup
    title 'Group Compartment Export Validation Tests'
    description <<~DESCRIPTION
      Verify that Group compartment export from the Bulk Data server follow US Core Implementation Guide
    DESCRIPTION

    id :bulk_data_group_export_validation

    input :bulk_status_output, :requires_access_token, :bearer_token
    input :lines_to_validate, description: 'To validate all, leave blank.', optional: true

    http_client :ndjson_endpoint do
      url :output_endpoint
    end 

    # TODO: Create after implementing TLS Tester Class.
    test do
      title 'Bulk Data Server is secured by transport layer security'
      description <<~DESCRIPTION
        [§170.315(g)(10) Test Procedure](https://www.healthit.gov/test-method/standardized-api-patient-and-population-services) requires that
        all exchanges described herein between a client and a server SHALL be secured using Transport Layer Security (TLS) Protocol Version 1.2 (RFC5246).
      DESCRIPTION
      # link 'http://hl7.org/fhir/uv/bulkdata/export/index.html#security-considerations'

      run {
        
      }
    end

    test do
      title 'NDJSON download requires access token if requireAccessToken is true'
      description <<~DESCRIPTION
        If the requiresAccessToken field in the Complete Status body is set to true, the request SHALL include a valid access token.

        [FHIR R4 Security](http://build.fhir.org/security.html#AccessDenied) and
        [The OAuth 2.0 Authorization Framework: Bearer Token Usage](https://tools.ietf.org/html/rfc6750#section-3.1)
        recommend using HTTP status code 401 for invalid token but also allow the actual result be controlled by policy and context.
      DESCRIPTION
      # link 'http://hl7.org/fhir/uv/bulkdata/export/index.html#file-request'

      run {
        skip 'Could not verify this functionality when Bulk Status Output is not provided' unless bulk_status_output.present? 
        skip 'Could not verify this functionality when requiresAccessToken is not provided' unless requires_access_token.present?
        skip 'Could not verify this functionality when requiresAccessToken is false' unless requires_access_token   
        skip 'Could not verify this functionality when Bearer Token is not provided' unless bearer_token.present? 

        output_endpoint = JSON.parse(bulk_status_output)[0]['url']

        get_file(output_endpoint, false)
        assert_response_status([400, 401])
      }
    end

    test do
      title 'Patient resources returned conform to the US Core Patient Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient'

      run {
        assert output_conforms_to_profile?('Patient', Array.wrap(USCore::PatientGroup::metadata)), 'Resources do not conform to profile.'
      }
    end

    test do
      title 'Group export has at least two patients'
      description <<~DESCRIPTION
        This test verifies that the Group export has at least two patients.
      DESCRIPTION
      # link 'http://ndjson.org/'

      run {
        skip 'No Patient resources processed from bulk data export.' unless patient_ids_seen.present?

        assert patient_ids_seen.length >= BulkDataUtils::MIN_RESOURCE_COUNT, 'Bulk data export did not have multiple Patient resources.'
      }
    end

    test do
      title 'Patient IDs match those expected in Group'
      description <<~DESCRIPTION
        This test checks that the list of patient IDs that are expected match those that are returned.
        If no patient ids are provided to the test, then the test will be omitted.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-patient'

      input :bulk_patient_ids_in_group

      run {
        omit 'No patient ids were given.' unless bulk_patient_ids_in_group.present?

        expected_ids = Set.new(bulk_patient_ids_in_group.split(',').map(&:strip))

        assert patient_ids_seen.sort == expected_ids.sort, "Mismatch between patient ids seen (#{patient_ids_seen.to_a.join(', ')}) and patient ids expected (#{bulk_patient_ids_in_group})"
      }
    end

    test do
      title 'AllergyIntolerance resources returned conform to the US Core AllergyIntolerance Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-allergyintolerance'

      run {
        assert output_conforms_to_profile?('AllergyIntolerance', Array.wrap(USCore::AllergyIntoleranceGroup::metadata)), 'Resources do not conform to profile.'
      }
    end

    test do
      title 'CarePlan resources returned conform to the US Core CarePlan Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-careplan'

      run {
        assert output_conforms_to_profile?('CarePlan', Array.wrap(USCore::CarePlanGroup::metadata)), 'Resources do not conform to profile.'
      }
    end

    test do
      title 'CareTeam resources returned conform to the US Core CareTeam Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-careteam'

      run {
        assert output_conforms_to_profile?('CareTeam', Array.wrap(USCore::CareTeamGroup::metadata)), 'Resources do not conform to profile.'
      }
    end


    test do
      title 'Condition resources returned conform to the US Core Condition Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-condition'

      run {
        assert output_conforms_to_profile?('Condition', Array.wrap(USCore::ConditionGroup::metadata)), 'Resources do not conform to profile.'
      }
    end

    # TODO: Make a note about device.
    test do
      title 'Device resources returned conform to the US Core Implantable Device Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-implantable-device'

      input :bulk_device_types_in_group, optional: true

      run {
        assert output_conforms_to_profile?('Device', Array.wrap(USCore::DeviceGroup::metadata)), 'Resources do not conform to profile.'
      }
    end

    test do
      title 'DiagnosticReport resources returned conform to the US Core DiagnosticReport Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the following US Core profiles. This includes checking for missing data elements and value set verification.

        * http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-lab
        * http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-note
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-diagnosticreport-l'

      run {
        metadata = [USCore::DiagnosticReportLabGroup::metadata, USCore::DiagnosticReportNoteGroup::metadata]
        assert output_conforms_to_profile?('DiagnosticReport', metadata), 'Resources do not conform to profile.'
      }
    end

    test do
      title 'DocumentReference resources returned conform to the US Core DocumentReference Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-documentreference'

      run {
        assert output_conforms_to_profile?('DocumentReference', [USCore::DocumentReferenceGroup::metadata]), 'Resources do not conform to profile.'
      }
    end

    test do
      title 'Goal resources returned conform to the US Core Goal Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-goal'
      run {
        assert output_conforms_to_profile?('Goal', [USCore::GoalGroup::metadata]), 'Resources do not conform to profile.'
      }
    end

    test do
      title 'Immunization resources returned conform to the US Core Immunization Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-Immunization'

      run {
        assert output_conforms_to_profile?('Immunization', [USCore::ImmunizationGroup::metadata]), 'Resources do not conform to profile.'
      }
    end

    test do
      title 'MedicationRequest resources returned conform to the US Core MedicationRequest Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-medicationrequest'

      run {
        assert output_conforms_to_profile?('MedicationRequest', [USCore::MedicationRequestGroup::metadata]), 'Resources do not conform to profile.'
      }
    end

    test do
      title 'Observation resources returned conform to the US Core Observation Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data
        export conform to the following US Core profiles. This includes
        checking for missing data elements and value set verification.

        * http://hl7.org/fhir/us/core/StructureDefinition/pediatric-bmi-for-age
        * http://hl7.org/fhir/us/core/StructureDefinition/pediatric-weight-for-height
        * http://hl7.org/fhir/us/core/StructureDefinition/us-core-observation-lab
        * http://hl7.org/fhir/us/core/StructureDefinition/us-core-pulse-oximetry
        * http://hl7.org/fhir/us/core/StructureDefinition/us-core-smokingstatus
        * http://hl7.org/fhir/us/core/StructureDefinition/head-occipital-frontal-circumference-percentile
        * http://hl7.org/fhir/StructureDefinition/bp
        * http://hl7.org/fhir/StructureDefinition/bodyheight
        * http://hl7.org/fhir/StructureDefinition/bodytemp
        * http://hl7.org/fhir/StructureDefinition/bodyweight
        * http://hl7.org/fhir/StructureDefinition/heartrate
        * http://hl7.org/fhir/StructureDefinition/resprate
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-observation-lab'

      run {
        metadata = [ USCore::PediatricBmiForAgeGroup::metadata, USCore::PediatricWeightForHeightGroup::metadata,
                      USCore::ObservationLabGroup::metadata, USCore::PulseOximetryGroup::metadata, USCore::SmokingstatusGroup::metadata, 
                      USCore::HeadCircumferenceGroup::metadata, USCore::BpGroup::metadata, USCore::BodyheightGroup::metadata, 
                      USCore::BodytempGroup::metadata, USCore::BodyweightGroup::metadata, USCore::HeartrateGroup::metadata, 
                      USCore::ResprateGroup::metadata ]

        assert output_conforms_to_profile?('Observation', metadata), 'Resources do not conform to profile.'
      }
    end

    test do
      title 'Procedure resources returned conform to the US Core Procedure Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-procedure'

      run {
        assert output_conforms_to_profile?('Procedure', [USCore::ProcedureGroup::metadata]), 'Resources do not conform to profile.'
      }
    end


    # TODO: Check USCOREEncounter checker 
    test do
      title 'Encounter resources returned conform to the US Core Encounter Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-encounter'

      run {
        assert output_conforms_to_profile?('Encounter', [USCore::EncounterGroup::metadata]), 'Resources do not conform to profile.'
      }
    end

    test do
      title 'Organization resources returned conform to the US Core Organization Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-organization'

      run {
        assert output_conforms_to_profile?('Organization', [USCore::OrganizationGroup::metadata]), 'Resources do not conform to profile.'
      }
    end

    test do
      title 'Practitioner resources returned conform to the US Core Practitioner Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-practitioner'

      run {
        assert output_conforms_to_profile?('Practitioner', [USCore::PractitionerGroup::metadata]), 'Resources do not conform to profile.'
      }
    end

    test do
      title 'Provenance resources returned conform to the US Core Provenance Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-provenance'

      run {
        assert output_conforms_to_profile?('Provenance', [USCore::ProvenanceGroup::metadata]), 'Resources do not conform to profile.'
      }
    end

    test do
      title 'Location resources returned conform to the US Core Location Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-location'

      run {
        metadata = YAML.load_file(File.join(__dir__, 'metadata/location.yml'))

        assert output_conforms_to_profile?('Location', [USCore::Generator::GroupMetadata.new(metadata)]), 'Resources do not conform to profile.'
      }
    end

    test do
      title 'Medication resources returned conform to the US Core Medication Profile'
      description <<~DESCRIPTION
        This test verifies that the resources returned from bulk data export conform to the US Core profiles. This includes checking for missing data elements and value set verification.
      DESCRIPTION
      # link 'http://hl7.org/fhir/us/core/StructureDefinition/us-core-medication'

      run {
        metadata = YAML.load_file(File.join(__dir__, 'metadata/medication.yml'))

        assert output_conforms_to_profile?('Medication', [USCore::Generator::GroupMetadata.new(metadata)]), 'Resources do not conform to profile.'
      }
    end
  end
end
