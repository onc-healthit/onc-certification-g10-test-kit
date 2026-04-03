gem_dir = Gem::Specification.find_by_name('smart_app_launch_test_kit').gem_dir
load "#{gem_dir}/execution_scripts/reference_server/base_ref_server_ehr_launch.rb"

ref_server_ehr_launch(ARGV[0], ARGV[1], 85)