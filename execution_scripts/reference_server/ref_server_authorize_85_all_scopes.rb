gem_dir = Gem::Specification.find_by_name('smart_app_launch_test_kit').gem_dir
load "#{gem_dir}/execution_scripts/reference_server/base_ref_server_authorize.rb"

ref_server_authorize(ARGV[0], target_patient_id: '85')
