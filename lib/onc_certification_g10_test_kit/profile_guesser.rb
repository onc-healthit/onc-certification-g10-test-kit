module ONCCertificationG10TestKit
  module ProfileGuesser
    def extract_profile(profile)
      case profile
      when 'Medication'
        return USCoreTestKit::USCoreV311::USCoreTestSuite.metadata.find do |meta|
                 meta.resource == profile
               end.profile_url
      when 'Location'
        return 'http://hl7.org/fhir/StructureDefinition/Location'
      end
      versioned_us_core_module.const_get("#{profile}Group").metadata.profile_url
    end

    def observation_contains_code(observation_resource, code)
      observation_resource&.code&.coding&.any? { |coding| coding&.code == code }
    end

    def resource_contains_category(resource, category_code, category_system = nil) # rubocop:disable Metrics/CyclomaticComplexity
      resource&.category&.any? do |category|
        category.coding&.any? do |coding|
          coding.code == category_code &&
            (category_system.blank? || coding.system.blank? || category_system == coding.system)
        end
      end
    end

    def guess_profile(resource) # rubocop:disable Metrics/CyclomaticComplexity
      case resource.resourceType
      when 'DiagnosticReport'
        return extract_profile('DiagnosticReportLab') if resource_contains_category(resource, 'LAB', 'http://terminology.hl7.org/CodeSystem/v2-0074')

        extract_profile('DiagnosticReportNote')
      when 'Observation'
        return extract_profile('Smokingstatus') if observation_contains_code(resource, '72166-2')

        return extract_profile('ObservationLab') if resource_contains_category(resource, 'laboratory', 'http://terminology.hl7.org/CodeSystem/observation-category')

        return extract_profile('PediatricBmiForAge') if observation_contains_code(resource, '59576-9')

        return extract_profile('PediatricWeightForHeight') if observation_contains_code(resource, '77606-2')

        return extract_profile('PulseOximetry') if observation_contains_code(resource, '59408-5')

        return extract_profile('HeadCircumference') if observation_contains_code(resource, '8289-1')

        # FHIR Vital Signs profiles: https://www.hl7.org/fhir/observation-vitalsigns.html
        # Vital Signs Panel, Oxygen Saturation are not required by USCDI
        # Body Mass Index is replaced by :pediatric_bmi_age Profile
        # Systolic Blood Pressure, Diastolic Blood Pressure are covered by :blood_pressure Profile
        # Head Circumference is replaced by US Core Head Occipital-frontal Circumference Percentile Profile
        return extract_profile('Bp') if observation_contains_code(resource, '85354-9')

        return extract_profile('Bodyheight') if observation_contains_code(resource, '8302-2')

        return extract_profile('Bodytemp') if observation_contains_code(resource, '8310-5')

        return extract_profile('Bodyweight') if observation_contains_code(resource, '29463-7')

        return extract_profile('Heartrate') if observation_contains_code(resource, '8867-4')

        return extract_profile('Resprate') if observation_contains_code(resource, '9279-1')

        nil
      else
        extract_profile(resource.resourceType)
      end
    rescue StandardError
      skip "Could not determine profile of \"#{resource.resourceType}\" resource."
    end
  end
end
