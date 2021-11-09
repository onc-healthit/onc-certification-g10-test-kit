require 'smart_app_launch_test_kit'
require 'us_core'

module G10CertificationTestKit
  class G10CertificationSuite < Inferno::TestSuite
    title '2015 Edition Cures Update - Standardized API Testing'

    group from: 'smart-smart_full_standalone_launch' do
      title 'Standalone Patient App'
    end

    group do
      title 'TODO: Limited App'

      test do
        title 'TODO'

        run { pass }
      end
    end

    group from: 'smart-smart_full_ehr_launch' do
      title 'EHR Practitioner App'
    end

    group do
      id :single_patient_api
      title 'Single Patient API'

      input :url,
            title: 'FHIR Endpoint',
            description: 'URL of the FHIR endpoint used by SMART applications',
            default: 'https://inferno.healthit.gov/reference-server/r4'
      input :patient_id, default: '85'
      input :bearer_token, optional: true, locked: true

      fhir_client do
        url :url
        bearer_token :bearer_token
      end

      test do
        id :preparation
        title 'Test preparation'
        input :standalone_access_token, optional: true, locked: true
        input :ehr_access_token, optional: true, locked: true
        # input :standalone_refresh_token, optional: true, locked: true
        # input :ehr_refresh_token, optional: true, locked: true

        output :bearer_token

        run do
          output bearer_token: standalone_access_token.presence || ehr_access_token.presence
        end
      end

      USCore::USCoreTestSuite.groups.each do |group|
        id = group.ancestors[1].id
        group from: id
      end
    end

    group do
      title 'TODO: Multi-Patient API'

      test do
        title 'TODO'

        run { pass }
      end
    end

    group do
      title 'TODO: Other'

      test do
        title 'TODO'

        run { pass }
      end
    end
  end
end
