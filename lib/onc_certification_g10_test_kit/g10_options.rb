module ONCCertificationG10TestKit
  module G10Options
    US_CORE_6 = 'us_core_6'.freeze
    US_CORE_7 = 'us_core_7'.freeze

    US_CORE_VERSION_NUMBERS = {
      US_CORE_6 => '6.1.0',
      US_CORE_7 => '7.0.0'
    }.freeze

    BULK_DATA_1 = 'multi_patient_api_stu1'.freeze
    BULK_DATA_2 = 'multi_patient_api_stu2'.freeze

    SMART_2 = 'smart_app_launch_2'.freeze
    SMART_2_2 = 'smart_app_launch_2_2'.freeze

    US_CORE_6_REQUIREMENT = { us_core_version: US_CORE_6 }.freeze
    US_CORE_7_REQUIREMENT = { us_core_version: US_CORE_7 }.freeze

    BULK_DATA_1_REQUIREMENT = { multi_patient_version: BULK_DATA_1 }.freeze
    BULK_DATA_2_REQUIREMENT = { multi_patient_version: BULK_DATA_2 }.freeze

    SMART_2_REQUIREMENT = { smart_app_launch_version: SMART_2 }.freeze
    SMART_2_2_REQUIREMENT = { smart_app_launch_version: SMART_2_2 }.freeze

    def us_core_version
      suite_options[:us_core_version]
    end

    def using_us_core_6?
      us_core_version == US_CORE_6
    end

    def using_us_core_7?
      us_core_version == US_CORE_7
    end

    def us_core_7_and_above?
      us_core_version[-1].to_i > 6
    end

    def versioned_us_core_module
      case us_core_version
      when US_CORE_7
        USCoreTestKit::USCoreV700
      else
        USCoreTestKit::USCoreV610
      end
    end
  end
end
