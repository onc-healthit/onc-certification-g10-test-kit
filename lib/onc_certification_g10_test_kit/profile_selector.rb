module ONCCertificationG10TestKit
  module ProfileSelector
    def extract_profile(profile)
      case profile
      when 'Medication'
        # TODO: verify why this is the case
        return versioned_us_core_module.const_get('USCoreTestSuite').metadata.find do |meta|
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

    def select_profile(resource) # rubocop:disable Metrics/CyclomaticComplexity
      case resource.resourceType
      when 'Condition'

        return extract_profile(resource.resourceType) unless Feature.us_core_v4?

        case suite_options[:us_core_version]
        when 'us_core_5'
          if resource_contains_category(resource, 'encounter-diagnosis', 'http://terminology.hl7.org/CodeSystem/condition-category')
            extract_profile('ConditionEncounterDiagnosis')
          elsif resource_contains_category(resource, 'problem-list-item',
                                           'http://terminology.hl7.org/CodeSystem/condition-category') ||
                resource_contains_category(resource, 'health-concern', 'http://terminology.hl7.org/CodeSystem/condition-category')
            extract_profile('ConditionProblemsHealthConcerns')
          end
        else
          extract_profile(resource.resourceType)
        end

      when 'DiagnosticReport'
        return extract_profile('DiagnosticReportLab') if resource_contains_category(resource, 'LAB', 'http://terminology.hl7.org/CodeSystem/v2-0074')

        extract_profile('DiagnosticReportNote')
      when 'Observation'
        return extract_profile('Smokingstatus') if observation_contains_code(resource, '72166-2')

        return extract_profile('ObservationLab') if resource_contains_category(resource, 'laboratory', 'http://terminology.hl7.org/CodeSystem/observation-category')

        return extract_profile('PediatricBmiForAge') if observation_contains_code(resource, '59576-9')

        return extract_profile('PediatricWeightForHeight') if observation_contains_code(resource, '77606-2')

        return extract_profile('PulseOximetry') if observation_contains_code(resource, '59408-5')

        if observation_contains_code(resource, '8289-1')
          return extract_profile('HeadCircumference') unless Feature.us_core_v4?

          case suite_options[:us_core_version]
          when 'us_core_3'
            return extract_profile('HeadCircumference')
          else
            return extract_profile('HeadCircumferencePercentile')
          end
        end

        if Feature.us_core_v4?
          return extract_profile('HeadCircumference') if observation_contains_code(resource, '9843-4') # rubocop:disable Style/SoleNestedConditional
        end

        # FHIR Vital Signs profiles: https://www.hl7.org/fhir/observation-vitalsigns.html
        # Vital Signs Panel, Oxygen Saturation are not required by USCDI
        # Body Mass Index is replaced by :pediatric_bmi_age Profile
        # Systolic Blood Pressure, Diastolic Blood Pressure are covered by :blood_pressure Profile
        # Head Circumference is replaced by US Core Head Occipital-frontal Circumference Percentile Profile
        if Feature.us_core_v4?
          if observation_contains_code(resource, '39156-5') && suite_options[:us_core_version] != 'us_core_3' # rubocop:disable Style/SoleNestedConditional
            return extract_profile('Bmi')
          end
        end

        if observation_contains_code(resource, '85354-9')
          return extract_profile('Bp') unless Feature.us_core_v4?

          case suite_options[:us_core_version]
          when 'us_core_3'
            return extract_profile('Bp')
          else
            return extract_profile('BloodPressure')
          end
        end

        if observation_contains_code(resource, '8302-2')
          return extract_profile('Bodyheight') unless Feature.us_core_v4?

          case suite_options[:us_core_version]
          when 'us_core_3'
            return extract_profile('Bodyheight')
          else
            return extract_profile('BodyHeight')
          end
        end

        if observation_contains_code(resource, '8310-5')
          return extract_profile('Bodytemp') unless Feature.us_core_v4?

          case suite_options[:us_core_version]
          when 'us_core_3'
            return extract_profile('Bodytemp')
          else
            return extract_profile('BodyTemperature')
          end
        end

        if observation_contains_code(resource, '29463-7')
          return extract_profile('Bodyweight') unless Feature.us_core_v4?

          case suite_options[:us_core_version]
          when 'us_core_3'
            return extract_profile('Bodyweight')
          else
            return extract_profile('BodyWeight')
          end
        end

        if observation_contains_code(resource, '8867-4')
          return extract_profile('Heartrate') unless Feature.us_core_v4?

          case suite_options[:us_core_version]
          when 'us_core_3'
            return extract_profile('Heartrate')
          else
            return extract_profile('HeartRate')
          end
        end

        if observation_contains_code(resource, '9279-1')
          return extract_profile('Resprate') unless Feature.us_core_v4?

          case suite_options[:us_core_version]
          when 'us_core_3'
            return extract_profile('Resprate')
          else
            return extract_profile('RespiratoryRate')
          end
        end
        if Feature.us_core_v4? # New profiles in us core v5 based on categories

          return extract_profile('ObservationClinicalTest') if suite_options[:us_core_version] == 'us_core_5' &&
                                                               resource_contains_category(
                                                                 resource, 'clinical-test', 'http://terminology.hl7.org/CodeSystem/observation-category'
                                                               )

          return extract_profile('ObservationSexualOrientation') if suite_options[:us_core_version] == 'us_core_5' &&
                                                                    observation_contains_code(resource, '76690-7')

          return extract_profile('ObservationSocialHistory') if suite_options[:us_core_version] == 'us_core_5' &&
                                                                resource_contains_category(resource, 'social-history',
                                                                                           'http://terminology.hl7.org/CodeSystem/observation-category')

          # We will simply match all Observations of category "survey" to SDOH,
          # and do not look at the category "sdoh".  US Core spec team says that
          # support for the "sdoh" category is limited, and the validation rules
          # allow for very generic surveys to validate against this profile.
          # And will not validate against the ObservationSurvey profile itself.
          # This may not be exactly precise but it works out the same

          # if we wanted to be more specific here, we would add:
          # `resource_contains_category(resource, 'sdoh',
          #                                       'http://terminology.hl7.org/CodeSystem/observation-category') &&`
          # along with a specific extract_profile('ObservationSurvey') to catch non-sdoh.
          return extract_profile('ObservationSdohAssessment') if suite_options[:us_core_version] == 'us_core_5' &&
                                                                 resource_contains_category(resource, 'survey', 'http://terminology.hl7.org/CodeSystem/observation-category') # rubocop:disable Layout/LineLength

        end

        nil
      else
        extract_profile(resource.resourceType)
      end
    rescue StandardError
      skip "Could not determine profile of \"#{resource.resourceType}\" resource."
    end
  end
end
