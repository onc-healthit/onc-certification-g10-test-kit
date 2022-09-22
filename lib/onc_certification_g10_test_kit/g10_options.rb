module ONCCertificationG10TestKit
  module G10Options
    US_CORE_3 = 'us_core_3'.freeze
    US_CORE_4 = 'us_core_4'.freeze
    US_CORE_5 = 'us_core_5'.freeze

    BULK_DATA_1 = 'multi_patient_api_stu1'.freeze
    BULK_DATA_2 = 'multi_patient_api_stu2'.freeze

    SMART_1 = 'smart_app_launch_1'.freeze
    SMART_2 = 'smart_app_launch_2'.freeze

    US_CORE_3_REQUIREMENT = { us_core_version: US_CORE_3 }.freeze
    US_CORE_4_REQUIREMENT = { us_core_version: US_CORE_4 }.freeze
    US_CORE_5_REQUIREMENT = { us_core_version: US_CORE_5 }.freeze

    BULK_DATA_1_REQUIREMENT = { multi_patient_version: BULK_DATA_1 }.freeze
    BULK_DATA_2_REQUIREMENT = { multi_patient_version: BULK_DATA_2 }.freeze

    SMART_1_REQUIREMENT = { smart_app_launch_version: SMART_1 }.freeze
    SMART_2_REQUIREMENT = { smart_app_launch_version: SMART_2 }.freeze
  end
end