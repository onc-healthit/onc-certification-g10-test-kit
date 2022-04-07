module ONCCertificationG10TestKit
  class SinglePatientAPIGroup < Inferno::TestGroup
    id :g10_single_patient_api
    title 'Single Patient API'
    description %(
      For each of the relevant USCDI data elements provided in the
      CapabilityStatement, this test executes the [required supported
      searches](http://www.hl7.org/fhir/us/core/STU3.1.1/CapabilityStatement-us-core-server.html)
      as defined by the US Core Implementation Guide v3.1.1.

      The test begins by searching by one or more patients, with the expectation
      that the Bearer token provided to the test grants access to all USCDI
      resources. It uses results returned from that query to generate other
      queries and checks that the results are consistent with the provided
      search parameters. It then performs a read on each Resource returned and
      validates the response against the relevant
      [profile](http://www.hl7.org/fhir/us/core/STU3.1.1/profiles.html) as
      currently defined in the US Core Implementation Guide.

      All MUST SUPPORT elements must be seen before the test can pass, as well
      as Data Absent Reason to demonstrate that the server can properly handle
      missing data. Note that Encounter, Organization and Practitioner resources
      must be accessible as references in some US Core profiles to satisfy must
      support requirements, and those references will be validated to their US
      Core profile. These resources will not be tested for FHIR search support.
    )
    run_as_group

    input :url,
          title: 'FHIR Endpoint',
          description: 'URL of the FHIR endpoint used by SMART applications'
    input :patient_id,
          title: 'Patient ID from SMART App Launch',
          locked: true
    input :additional_patient_ids,
          title: 'Additional Patient IDs',
          description: <<~DESCRIPTION,
            Comma separated list of Patient IDs that together with the Patient
            ID from the SMART App Launch contain all MUST SUPPORT elements.
          DESCRIPTION
          optional: true
    input :smart_credentials,
          title: 'SMART App Launch Credentials',
          type: :oauth_credentials,
          locked: true

    fhir_client do
      url :url
      oauth_credentials :smart_credentials
    end

    input_order :url, :patient_id, :additional_patient_ids, :implantable_device_codes, :smart_credentials

    test do
      id :g10_patient_id_setup
      title 'Manage patient id list'

      input :patient_id, :additional_patient_ids
      output :patient_ids

      run do
        smart_app_launch_patient_id = patient_id.presence
        additional_patient_ids_list =
          additional_patient_ids
            .split(',')
            .map(&:strip)
            .map(&:presence)
            .compact

        all_patient_ids = ([smart_app_launch_patient_id] + additional_patient_ids_list).compact.uniq

        output patient_ids: all_patient_ids.join(',')
      end
    end

    USCoreTestKit::USCoreTestSuite.groups.each do |group|
      test_group = group.ancestors[1]
      id = test_group.id

      group_config = {}
      if test_group.respond_to?(:metadata) && test_group.metadata.delayed?
        test_group.children.reject! { |child| child.include? USCoreTestKit::SearchTest }
        group_config[:options] = { read_all_resources: true }
      end

      group(from: id, exclude_optional: true, config: group_config)
    end
  end
end
