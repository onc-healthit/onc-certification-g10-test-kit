Dir.glob(File.join(__dir__, 'multi_patient_api', '*.rb')).each { |path| require_relative path.delete_prefix("#{__dir__}/") }
#require_relative 'multi_patient_api/bulk_data_authorization'

module MultiPatientAPI
  class MultiPatientAPISuite < Inferno::TestGroup

    id 'multi_patient_api'
    title 'Multiple Patient API'

    group from: :bulk_data_authorization
    #group from: :bulk_data_group_export
    #group from: :bulk_data_group_export_validation
  end
end 