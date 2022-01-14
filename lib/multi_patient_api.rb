Dir.glob(File.join(__dir__, 'multi_patient_api', '*.rb')).each do |path|
  require_relative path.delete_prefix("#{__dir__}/")
end

module MultiPatientAPI
  class MultiPatientAPIGroup < Inferno::TestGroup
    id 'multi_patient_api'
    title 'Multiple Patient API'

    group from: :bulk_data_authorization
    group from: :bulk_data_group_export
    group from: :bulk_data_group_export_validation
  end
end
